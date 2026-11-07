# Chardumps #

**Chardumps** this is an addon for World od Warcraft game, supported version 3.3.5a officially, but works on the major versions. Allow to save information, the game process, about every character to the file. This file may be use for character's transfer to some servers.

The addon can to save:

- Common information (language, realm, server, client version, lua version)
- Basic character information (name, class, race, level, money, gender, honorable kills, double specialisation, honor points and arena points)
- Achievements
- Actions
- Items in the bags
- Items in the bank
- Statistics
- Criterias of the achievements
- Critters
- Currency
- Glyphs
- Inventory (equipped items, equipped bags, main backpack, main bank, bank bags and keys in the keyring)
- Player macroses
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
- Encode data as Base64 JSON (this is neither encryption nor compression)
- Debug mode


## For developers

1. For GUI design use WowAddOnStudio, https://addonstudio.codeplex.com.
2. For lua editing use Eclipse, http://www.eclipse.org/ldt.
3. For debug mode run command /chardumps debug

## Capture notes

Press Dump, then Save or log out to write the per-character SavedVariables file.
The last saved dump is retained across reloads until another dump replaces it.
Copy it elsewhere for a separate backup. A dump with failed collectors is marked
in `CHD_ERRORS` and a warning is displayed in chat.

Before dumping, enable the relevant categories, open the bank, open each of the
character's profession windows, query completed quests in the Quests view, and
visit flight masters on each continent. These categories use cached observations
and can be incomplete or stale. Account settings from older versions were keyed
by character name alone; the first realm to load a name claims its legacy cache.
Check that cache if characters share a name across realms.

Item links and bag slots are included alongside the original item fields, and
money is also recorded in copper. A client item link is not a complete server
item record: this addon does not capture everything needed to restore a character.
Actions, bindings, equipment sets, pets and character macros are disabled in the
current interface. An AzerothCore importer is not included.
