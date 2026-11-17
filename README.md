# Chardumps #

**Chardumps** this is an addon for World od Warcraft game, supported version 3.3.5a officially, but works on the major versions. Allow to save information, the game process, about every character to the file. This file may be use for character's transfer to some servers.

The addon can to save:

- Common information (language, realm, server, client version, lua version)
- Basic character information (name, class, race, level, money, gender, honorable kills, double specialisation, honor points and arena points)
- Achievements
- Items in the bags
- Items in the bank
- Statistics
- Criterias of the achievements
- Critters
- Currency
- Glyphs
- Inventory (equipped items, equipped bags, main backpack, main bank, bank bags and keys in the keyring)
- Mounts
- Quests
- Quest log
- Reputation
- Skills and professions
- Spells
- Taxi
- Recipes


## Features
- One simple window
- Save player data to the file, called dump
- Dynamic sets and unsets the dump options
- Divide player data and addon options
- Each data entity has view
- Mimimize and restore main window
- Console commands
- Save graphic interface
- Debug mode


## For developers

1. For GUI design use WowAddOnStudio, https://addonstudio.codeplex.com.
2. For lua editing use Eclipse, http://www.eclipse.org/ldt.
3. For debug mode run command /chardumps debug

## Capture notes

Press Dump for each character, then Save or log out to write the account-wide
`WTF/Account/<account>/SavedVariables/chardumps.lua` file. `CHD_ACCOUNT_DUMPS`
contains the latest dump for each realm and character, keyed by realm then name.
The addon can only capture the character currently logged in; it does not
automatically scan the account. Each new dump replaces only that character's entry.
Existing per-character `CHD_CLIENT` dumps are copied into the account collection
when that character logs in, if no account entry exists. The per-character dump
is also retained for compatibility. Separate WoW accounts have separate files.
Copy it elsewhere for a separate backup. A dump with failed collectors is marked
in `CHD_ERRORS` and a warning is displayed in chat.

Before dumping, enable the relevant categories, open the bank, open each of the
character's profession windows, query completed quests in the Quests view, and
visit flight masters on each continent. These categories use cached observations
and can be incomplete or stale. Account settings from older versions were keyed
by character name alone; the first realm to load a name claims its legacy cache.
Check that cache if characters share a name across realms. Names are scoped by
realm inside each WoW account folder, but not by server address: if two different
servers use the same account folder, realm name, and character name, back up the
source file before switching servers, because their snapshots use the same key.

The small square beside each category selects it for the dump; clicking the
category name only opens its view. Select **Inventory** for equipped items,
the backpack and keyring, and **Bags** for the contents of equipped bags. The
top **Select all** checkbox selects all available categories. Bank contents
also require **Bank** to be selected and the bank to have been opened.

Item links and bag slots are included alongside the original item fields, and
money is also recorded in copper. Container quality and durability are included
when the running client exposes them; equipped-item durability is recorded when
available. A client item link is not a complete server item record: this addon
does not capture everything needed to restore a character.
Actions, bindings, equipment sets, pets and character macros are disabled in the
current interface.

For playtime, type `/played` on the character and wait for the response before
pressing Dump. The addon records total and current-level seconds and the time
they were received. This is a snapshot and does not update until `/played` is
requested again. No automatic playtime request is sent by the addon.

## Overview and guild banks

Press **Overview** or use `/chardumps overview` for the current character's
collection checklist, account snapshot list, and guild-bank tabs. Statuses mean
an observation was made, not that its contents are complete or up to date.
Older cached data without collection metadata is shown as unknown. An observed
profession or continent does not establish that all professions or continents
were visited. Checks show what was selected for the last dump; a collector
failure is listed separately. Save or log out to persist changes.

To capture a guild bank, open it, select an accessible tab and wait until its
contents finish loading. Type `/chardumps guildbank` for each tab you want to
record. The addon reads the visible tab without switching tabs or issuing its
own guild-bank queries. The account SavedVariables file stores guild snapshots
separately by realm and guild name, including observation times and the last
character's visible-tab permissions. Unobserved or inaccessible tabs are not
treated as empty. As with personal inventory, client-visible item information is
not a complete server item record. Guild data may change after observation.

## Export review package

Snapshots have `CHD_SCHEMA_VERSION = 1` plus selection, collection and error
metadata. Legacy snapshots remain readable. With Python 3, list and stage an
account's SavedVariables file from the project folder, for example:

```powershell
python tools/stage.py list "C:\path\to\WTF\Account\ACCOUNT\SavedVariables\chardumps.lua"
python tools/stage.py stage "C:\path\to\WTF\Account\ACCOUNT\SavedVariables\chardumps.lua" --source-account "account-label" --realm "Realm" --character "Character" --output "C:\path\to\new-review-folder"
```

The output folder must not already exist. It contains the original account file
byte-for-byte, the selected decoded snapshot, guild-bank observations, a report
of capture gaps and candidate AzerothCore mappings, and SHA-256 hashes in a
manifest. The original account file may contain other characters' data. The
tool parses SavedVariables as data; it does not execute Lua, connect to MySQL,
or modify a game database. It rejects unknown snapshot versions. It is a review
and staging tool, **not a completed importer**: target DBC IDs, character and item
GUIDs, faction standings, spec masks, missing data, and database migrations still
need validation and implementation. See `docs/LIVE_VALIDATION.md` before relying
on a capture or writing an importer.

Optionally append `--dbc-dir "D:\WotLK Singleplayer\Server\Data\dbc"` to the
stage command to check achievement, spell and faction ID presence against that
local server's DBC files. The report includes their hashes and unknown IDs; ID
presence alone does not prove a mapping or imported character will work.
