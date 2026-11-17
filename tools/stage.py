#!/usr/bin/env python3
"""Read WoW SavedVariables as data and stage one character for later import.

This does not evaluate Lua or connect to a database. The source is retained
byte-for-byte so later converters can revisit fields this version does not map.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import re
import struct
import sys
from pathlib import Path
from typing import Any


class ParseError(ValueError):
    pass


class LuaDataParser:
    """Parser for the literal-only subset used by WoW SavedVariables."""

    name = re.compile(r"[A-Za-z_][A-Za-z_0-9]*")
    number = re.compile(r"-?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?")

    def __init__(self, source: str):
        self.source, self.pos, self.depth = source, 0, 0

    def fail(self, message: str) -> None:
        raise ParseError(f"{message} at character {self.pos}")

    def skip(self) -> None:
        while self.pos < len(self.source):
            if self.source[self.pos].isspace():
                self.pos += 1
            elif self.source.startswith("--[[", self.pos):
                end = self.source.find("]]", self.pos + 4)
                if end < 0:
                    self.fail("Unterminated comment")
                self.pos = end + 2
            elif self.source.startswith("--", self.pos):
                end = self.source.find("\n", self.pos + 2)
                self.pos = len(self.source) if end < 0 else end + 1
            else:
                return

    def take(self, char: str) -> bool:
        self.skip()
        if self.source.startswith(char, self.pos):
            self.pos += len(char)
            return True
        return False

    def require(self, char: str) -> None:
        if not self.take(char):
            self.fail(f"Expected {char!r}")

    def identifier(self) -> str | None:
        self.skip()
        match = self.name.match(self.source, self.pos)
        if not match:
            return None
        self.pos = match.end()
        return match.group()

    def string(self) -> str:
        quote = self.source[self.pos]
        self.pos += 1
        result = bytearray()
        escapes = {"a": "\a", "b": "\b", "f": "\f", "n": "\n", "r": "\r",
                   "t": "\t", "v": "\v", "\\": "\\", '"': '"', "'": "'"}
        while self.pos < len(self.source):
            char = self.source[self.pos]
            self.pos += 1
            if char == quote:
                try:
                    return result.decode("utf-8")
                except UnicodeDecodeError as exc:
                    raise ParseError(f"String is not valid UTF-8 at character {self.pos}") from exc
            if char != "\\":
                if char in "\r\n":
                    self.fail("Unescaped newline in string")
                result.extend(char.encode("utf-8"))
                continue
            if self.pos >= len(self.source):
                self.fail("Unterminated string escape")
            char = self.source[self.pos]
            self.pos += 1
            if char.isdigit() and char.isascii():
                digits = char
                while len(digits) < 3 and self.pos < len(self.source) and self.source[self.pos] in "0123456789":
                    digits += self.source[self.pos]
                    self.pos += 1
                if int(digits) > 255:
                    self.fail("Invalid decimal escape")
                result.append(int(digits))
            elif char in escapes:
                result.extend(escapes[char].encode("utf-8"))
            elif char == "\n":
                result.append(10)
            elif char == "\r":
                if self.pos < len(self.source) and self.source[self.pos] == "\n":
                    self.pos += 1
                result.append(10)
            else:
                self.fail("Unsupported string escape")
        self.fail("Unterminated string")

    def value(self) -> Any:
        self.skip()
        if self.pos >= len(self.source):
            self.fail("Expected value")
        char = self.source[self.pos]
        if char in "\"'":
            return self.string()
        if char == "{":
            return self.table()
        match = self.number.match(self.source, self.pos)
        if match:
            self.pos = match.end()
            text = match.group()
            return float(text) if any(c in text for c in ".eE") else int(text)
        word = self.identifier()
        if word in ("true", "false", "nil"):
            return {"true": True, "false": False, "nil": None}[word]
        self.fail("Only literal values are supported")

    def table(self) -> dict:
        self.depth += 1
        if self.depth > 80:
            self.fail("Maximum nesting depth exceeded")
        self.require("{")
        result, index = {}, 1
        while not self.take("}"):
            if self.take("["):
                key = self.value()
                self.require("]")
                self.require("=")
                value = self.value()
            else:
                start = self.pos
                key = self.identifier()
                if key is not None and self.take("="):
                    value = self.value()
                else:
                    self.pos = start
                    key, value = index, self.value()
                    index += 1
            if not isinstance(key, (str, int)) or isinstance(key, bool):
                self.fail("Unsupported table key")
            if key in result:
                self.fail("Duplicate table key")
            result[key] = value
            if not self.take(",") and not self.take(";"):
                self.require("}")
                break
        self.depth -= 1
        return result

    def assignments(self) -> dict:
        result = {}
        while True:
            self.skip()
            if self.pos >= len(self.source):
                return result
            name = self.identifier()
            if not name:
                self.fail("Expected variable name")
            self.require("=")
            if name in result:
                self.fail("Duplicate assignment")
            result[name] = self.value()
            self.take(";")


def load_source(path: Path) -> tuple[bytes, dict]:
    raw = path.read_bytes()
    if len(raw) > 128 * 1024 * 1024:
        raise ValueError("SavedVariables file exceeds the 128 MiB limit")
    return raw, LuaDataParser(raw.decode("utf-8-sig")).assignments()


def decode_dump(value: Any) -> dict:
    if isinstance(value, str):
        decoded = base64.b64decode(value, validate=True).decode("utf-8")
        value = json.loads(decoded, parse_constant=lambda _: (_ for _ in ()).throw(ValueError("Invalid JSON number")))
    if not isinstance(value, dict):
        raise ValueError("Character dump is not an object")
    version = value.get("CHD_SCHEMA_VERSION")
    if version is not None and (type(version) is not int or version != 1):
        raise ValueError(f"Unsupported snapshot schema version: {version!r}")
    return value


def as_json(value: Any) -> Any:
    if isinstance(value, dict):
        result = {}
        for key, item in value.items():
            json_key = str(key)
            if json_key in result:
                raise ValueError(f"Conflicting numeric and string key: {json_key}")
            result[json_key] = as_json(item)
        return result
    if isinstance(value, list):
        return [as_json(item) for item in value]
    if isinstance(value, float) and not (-float("inf") < value < float("inf")):
        raise ValueError("Non-finite number")
    return value


def dump_json(value: Any) -> bytes:
    return (json.dumps(as_json(value), ensure_ascii=False, indent=2, sort_keys=True, allow_nan=False) + "\n").encode("utf-8")


def character_dump(data: dict, realm: str, character: str) -> dict:
    accounts = data.get("CHD_ACCOUNT_DUMPS")
    if not isinstance(accounts, dict) or not isinstance(accounts.get(realm), dict):
        raise ValueError("Realm not found in CHD_ACCOUNT_DUMPS")
    if character not in accounts[realm]:
        raise ValueError("Character not found in CHD_ACCOUNT_DUMPS")
    return decode_dump(accounts[realm][character])


def build_report(snapshot: dict) -> dict:
    capture = snapshot.get("CHD_CAPTURE") or {}
    selected = capture.get("selected") or {}
    collection = capture.get("collection") or {}
    errors = snapshot.get("CHD_ERRORS") or {}
    warnings = []
    if snapshot.get("CHD_SCHEMA_VERSION") is None:
        warnings.append("Legacy dump: schema and selection metadata are unknown.")
    for key in ("bank", "quest", "skillspell", "taxi", "playtime"):
        record = collection.get(key) or {}
        if key != "playtime" and snapshot.get("CHD_SCHEMA_VERSION") == 1 and not selected.get(key):
            warnings.append(f"{key}: category was not selected for this dump.")
        if record.get("state") != "collected":
            warnings.append(f"{key}: collection status is {record.get('state', 'unknown')}.")
    for key in ("achievement", "criterias", "reputation", "inventory", "bag", "spell", "talent", "skill"):
        if snapshot.get("CHD_SCHEMA_VERSION") == 1 and not selected.get(key):
            warnings.append(f"{key}: category was not selected for this dump.")
    if not (snapshot.get("player") or {}).get("playtime"):
        warnings.append("playtime: no playtime values were included in this snapshot.")
    warnings.append("Profession and flight path observations do not establish complete coverage.")
    if errors:
        warnings.append("One or more collectors failed; inspect collector_errors.")
    mappings = {
        "player": "characters: identity, money and playtime require target character and validation",
        "achievement": "character_achievement: ID and date; validate target DBC and date semantics",
        "criterias": "character_achievement_progress: progress date was not captured",
        "reputation": "character_reputation: client values require base-standing and flag conversion",
        "quest": "character_queststatus_rewarded: validate quest IDs and repeatable semantics",
        "spell": "character_spell: spellbook tab is not a talent-spec mask",
        "talent": "character_talent: resolve talent ranks to target spell IDs",
        "inventory": "character_inventory and item_instance: allocate GUIDs, map slots and item properties",
        "bag": "character_inventory and item_instance: map bag ownership, slots and item properties",
        "bank": "character_inventory and item_instance: map personal bank slots and bag ownership",
        "guildbank": "guild_bank_item and item_instance: separate guild snapshot, permissions and GUIDs",
    }
    return {
        "schema_version": 1,
        "mode": "review_only_no_database_writes",
        "capture_schema_version": snapshot.get("CHD_SCHEMA_VERSION"),
        "selected": selected,
        "collection": collection,
        "collector_errors": errors,
        "field_counts": snapshot.get("CHD_FIELD_COUNT") or {},
        "candidate_mappings_not_imported": mappings,
        "warnings": warnings,
        "limitations": [
            "No database connection or executable import is produced.",
            "Target IDs, player ownership, item instances and database schema require validation.",
            "Client-side snapshots cannot reconstruct data not exposed by the source client.",
        ],
    }


def dbc_ids(path: Path) -> tuple[set[int], str]:
    data = path.read_bytes()
    if len(data) < 20:
        raise ValueError(f"Truncated DBC: {path.name}")
    magic, count, fields, record_size, string_size = struct.unpack_from("<4s4I", data)
    if magic != b"WDBC" or fields < 1 or record_size < 4 or record_size != fields * 4:
        raise ValueError(f"Unsupported DBC layout: {path.name}")
    expected = 20 + count * record_size + string_size
    if expected != len(data):
        raise ValueError(f"DBC size does not match header: {path.name}")
    ids = {struct.unpack_from("<I", data, 20 + i * record_size)[0] for i in range(count)}
    return ids, hashlib.sha256(data).hexdigest()


def id_map_keys(value: Any) -> set[int]:
    if isinstance(value, list):
        return set(range(1, len(value) + 1))
    if not isinstance(value, dict):
        raise ValueError("Expected an ID-keyed table")
    result = set()
    for key in value:
        if not str(key).isdigit():
            raise ValueError(f"Invalid numeric ID key: {key!r}")
        result.add(int(key))
    return result


def validate_dbc(snapshot: dict, directory: Path) -> dict:
    if not directory.is_dir():
        raise ValueError("DBC directory does not exist")
    reputation = snapshot.get("reputation") or []
    rep_rows = reputation.values() if isinstance(reputation, dict) else reputation
    rep_ids = set()
    for row in rep_rows:
        if not isinstance(row, dict) or type(row.get("I")) is not int:
            raise ValueError("Invalid reputation row")
        rep_ids.add(row["I"])
    checks = {
        "achievement": ("Achievement.dbc", id_map_keys(snapshot.get("achievement") or {})),
        "spell": ("Spell.dbc", id_map_keys(snapshot.get("spell") or {})),
        "reputation": ("Faction.dbc", rep_ids),
    }
    report = {}
    for name, (filename, source_ids) in checks.items():
        path = directory / filename
        if not path.is_file():
            report[name] = {"file": filename, "status": "missing", "source_count": len(source_ids)}
            continue
        valid_ids, digest = dbc_ids(path)
        report[name] = {"file": filename, "sha256": digest, "source_count": len(source_ids),
                        "missing_ids": sorted(source_ids - valid_ids), "status": "checked_id_presence_only"}
    return report


def stage(args: argparse.Namespace) -> None:
    raw, data = load_source(args.source)
    snapshot = character_dump(data, args.realm, args.character)
    snapshot_bytes = dump_json(snapshot)
    report = build_report(snapshot)
    if args.dbc_dir:
        report["dbc_validation"] = validate_dbc(snapshot, args.dbc_dir)
    report_bytes = dump_json(report)
    guilds_bytes = dump_json(data.get("CHD_GUILD_BANKS") or {})
    manifest = {
        "stage_schema_version": 1,
        "source_account_label": args.source_account,
        "realm": args.realm,
        "character": args.character,
        "capture_schema_version": snapshot.get("CHD_SCHEMA_VERSION"),
        "capture_metadata": snapshot.get("global") or {},
        "source_file_name": args.source.name,
        "source_sha256": hashlib.sha256(raw).hexdigest(),
        "snapshot_sha256": hashlib.sha256(snapshot_bytes).hexdigest(),
        "report_sha256": hashlib.sha256(report_bytes).hexdigest(),
        "guild_banks_sha256": hashlib.sha256(guilds_bytes).hexdigest(),
    }
    args.output.mkdir(parents=False, exist_ok=False)
    (args.output / "source-savedvariables.lua").write_bytes(raw)
    (args.output / "snapshot.json").write_bytes(snapshot_bytes)
    (args.output / "report.json").write_bytes(report_bytes)
    (args.output / "guild-banks.json").write_bytes(guilds_bytes)
    (args.output / "manifest.json").write_bytes(dump_json(manifest))
    print(f"Staged {args.character} on {args.realm} in {args.output}")
    print("Review report.json. No game database was changed.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    listing = sub.add_parser("list", help="List characters in account SavedVariables")
    listing.add_argument("source", type=Path)
    staging = sub.add_parser("stage", help="Create a new, read-only import review package")
    staging.add_argument("source", type=Path)
    staging.add_argument("--source-account", required=True, help="A label, never a password")
    staging.add_argument("--realm", required=True)
    staging.add_argument("--character", required=True)
    staging.add_argument("--output", type=Path, required=True, help="New directory; parent must exist")
    staging.add_argument("--dbc-dir", type=Path, help="Optional target 3.3.5 DBC directory for ID checks")
    args = parser.parse_args()
    try:
        if args.command == "list":
            _, data = load_source(args.source)
            accounts = data.get("CHD_ACCOUNT_DUMPS") or {}
            for realm in sorted(accounts):
                for character in sorted(accounts[realm]):
                    print(f"{realm}\t{character}")
        else:
            stage(args)
    except (OSError, UnicodeError, ValueError, TypeError, RecursionError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
