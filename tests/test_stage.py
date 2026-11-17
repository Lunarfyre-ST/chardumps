import base64
import hashlib
import importlib.util
import json
import subprocess
import struct
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / "tools" / "stage.py"
spec = importlib.util.spec_from_file_location("stage", STAGE)
stage = importlib.util.module_from_spec(spec)
spec.loader.exec_module(stage)


class StageTests(unittest.TestCase):
    def test_parser_handles_savedvariables_and_rejects_code(self):
        result = stage.LuaDataParser('x = { ["realm"] = { ["name"] = "a\\010b", }, 7, true }').assignments()
        self.assertEqual(result["x"]["realm"]["name"], "a\nb")
        self.assertEqual(result["x"][1], 7)
        self.assertIs(result["x"][2], True)
        self.assertEqual(stage.LuaDataParser(r'x = "\195\164"').assignments()["x"], "ä")
        for text in ("x = os.execute('bad')", "x = { [1] = 2, [1] = 3 }", "x = 1 x = 2"):
            with self.subTest(text=text), self.assertRaises(stage.ParseError):
                stage.LuaDataParser(text).assignments()

    def test_unencoded_and_encoded_versions(self):
        obj = {"CHD_SCHEMA_VERSION": 1, "player": {"name": "Test"}}
        encoded = base64.b64encode(json.dumps(obj).encode()).decode()
        self.assertEqual(stage.decode_dump(encoded), obj)
        self.assertEqual(stage.decode_dump(obj), obj)
        self.assertEqual(stage.decode_dump({"player": {}}), {"player": {}})
        with self.assertRaises(ValueError):
            stage.decode_dump({"CHD_SCHEMA_VERSION": 2})
        with self.assertRaises(ValueError):
            stage.as_json({1: "numeric", "1": "string"})

    def test_stage_preserves_source_and_will_not_overwrite(self):
        dump = {"CHD_SCHEMA_VERSION": 1, "player": {"name": "Test"},
                "CHD_CAPTURE": {"selected": {"bank": True}, "collection": {"bank": {"state": "collected"}}}}
        encoded = base64.b64encode(json.dumps(dump).encode()).decode()
        raw = ('CHD_ACCOUNT_DUMPS = { ["Realm"] = { ["Test"] = "' + encoded + '" } }\n'
               'CHD_GUILD_BANKS = { ["Realm"] = { ["Guild"] = {} } }\n').encode()
        with tempfile.TemporaryDirectory() as tmp:
            source, output = Path(tmp) / "chardumps.lua", Path(tmp) / "staged"
            source.write_bytes(raw)
            cmd = [sys.executable, str(STAGE), "stage", str(source), "--source-account", "source-1",
                   "--realm", "Realm", "--character", "Test", "--output", str(output)]
            first = subprocess.run(cmd, capture_output=True, text=True)
            self.assertEqual(first.returncode, 0, first.stderr)
            manifest = json.loads((output / "manifest.json").read_text(encoding="utf-8"))
            self.assertEqual((output / "source-savedvariables.lua").read_bytes(), raw)
            self.assertEqual(manifest["source_sha256"], hashlib.sha256(raw).hexdigest())
            self.assertEqual(manifest["snapshot_sha256"], hashlib.sha256((output / "snapshot.json").read_bytes()).hexdigest())
            self.assertEqual(json.loads((output / "snapshot.json").read_text(encoding="utf-8")), dump)
            self.assertEqual(json.loads((output / "report.json").read_text(encoding="utf-8"))["mode"],
                             "review_only_no_database_writes")
            second = subprocess.run(cmd, capture_output=True, text=True)
            self.assertNotEqual(second.returncode, 0)
            self.assertEqual((output / "source-savedvariables.lua").read_bytes(), raw)

    def test_optional_dbc_checks_identify_missing_ids(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            def make_dbc(name, ids):
                blob = struct.pack("<4s4I", b"WDBC", len(ids), 1, 4, 1)
                blob += b"".join(struct.pack("<I", i) for i in ids) + b"\0"
                (directory / name).write_bytes(blob)
            make_dbc("Achievement.dbc", [1, 3])
            make_dbc("Spell.dbc", [4])
            make_dbc("Faction.dbc", [5])
            report = stage.validate_dbc({"achievement": {"1": 100, "2": 200},
                                         "spell": {"4": 1}, "reputation": [{"I": 5}, {"I": 6}]}, directory)
            self.assertEqual(report["achievement"]["missing_ids"], [2])
            self.assertEqual(report["spell"]["missing_ids"], [])
            self.assertEqual(report["reputation"]["missing_ids"], [6])
            (directory / "Spell.dbc").write_bytes(b"bad")
            with self.assertRaises(ValueError):
                stage.validate_dbc({}, directory)


if __name__ == "__main__":
    unittest.main()
