# In-game capture comparison

Use a character whose equipment, achievements and bank contents can be inspected.
This is a comparison checklist, not a claim that the addon has been tested on a
particular server. Do not overwrite an existing installation or SavedVariables
file without backing it up first. Record the source realm, server, client build,
addon revision, character, and date of the test; avoid recording credentials.

1. Log in with the addon enabled. Open Overview and record the initial checklist.
   Select the categories to collect. Check that legacy caches are not labeled
   freshly collected and unchecked categories are identified in the overview.
2. Open the personal bank, query completed quests in the addon, open each
   profession, visit a flight master in each relevant continent, and use
   `/played`. Confirm the respective status and time change. Empty data and a
   failed/inaccessible collection must not look like a successful full scan.
3. With permission, open a guild bank. Wait for an accessible tab to finish
   loading and run `/chardumps guildbank`. Repeat for each accessible tab; leave
   any others unobserved. Compare item links, stack sizes, gold and slots, and
   verify no item moves or extra tab requests occur. Test an inaccessible or
   still-loading tab if practical; an earlier snapshot must not be erased.
4. Dump and Save, then reload. Verify the per-character data survives and the
   account overview records the character. Repeat on another character, checking
   that personal bank, guild data and playtime are distinct and that the first
   character's snapshot remains unchanged. The dump captures only the active
   character; it cannot enumerate characters never logged into with the addon.
5. Stage the account SavedVariables file with `tools/stage.py`. Compare the
   decoded snapshot to the character in-game: equipped slots, item links and
   counts, bag positions, bank slots, achievement IDs and calendar dates,
   reputation standings, completed quests, and `/played` totals. Record gaps or
   unexpected values; compare as close to collection time as practical.
6. Test empty or partially collected categories and an intentionally disabled
   checkbox. Confirm that counts of zero are not interpreted as proof of a full
   capture, errors are shown, and older snapshots are not silently replaced by
   failed guild-bank reads. Keep source files and the review manifest for audit.

Item links do not include all server-side item instance fields; addon snapshots
are not full database backups. Do not apply any future importer to a real player
account until mappings, schema revision, ownership, IDs and recovery have been
tested against a disposable local character and a backup is available.
