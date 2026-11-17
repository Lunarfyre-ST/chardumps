-- Run from the project root with Lua 5.1.
chardumps = {log = {Message = function() end, Error = function() end,
  Warning = function() end, Debug = function() end}}
chardumps.MAX_NUM_CONTINENT = 4
local realm, character = 'Realm A', 'Example'
time = function() return 12345 end
UnitName = function() return character end
GetRealmName = function() return realm end
dofile('functions.lua')
dofile('capture_status.lua')
dofile('guild_bank.lua')
dofile('entity_manager.lua')
dofile('dumper.lua')
dofile('main_frame.lua')
function chardumps:GetLocale() return {} end
function chardumps:GetPatchVersion() return 3 end
chardumps.mainFrame.UpdateEntityText = function() end
chardumps.mainFrame.UpdateEntityView = function() end

MAX_SKILLLINE_TABS, BOOKTYPE_SPELL = 1, 'spell'
GetSpellTabInfo = function() return 'General', nil, 0, 2 end
GetSpellLink = function(i) return '|Hspell:' .. (100 + i) .. '|h' end
strmatch = string.match
local spells = chardumps.dumper:GetSpellData()
assert(spells[101] == 1 and spells[102] == 1)
GetNumTalents = function(tab) return tab == 1 and 2 or 0 end
GetTalentInfo = function(tab, i) return 'Talent', nil, 1, 1, i, 5 end
GetTalentLink = function(tab, i) return '|Htalent:' .. (200 + i) .. '|h' end
local talents = chardumps.dumper:GetTalentData()
assert(talents[1][201] == 1 and talents[2][202] == 2)

local d = chardumps.dumper
local getBagData = d.GetBagData
d.dynamicDump = {bank = {mainbank = {[40] = {I = 5}}}}
d.GetBagData = function() return {{{I = 1}, {I = 2}}} end
d.GetSpellData = function() error('test failure') end
local ok = d:Dump({entities = {bag = true, spell = true}})
assert(not ok and CHD_CLIENT.CHD_ERRORS.spell)
assert(CHD_CLIENT.CHD_FIELD_COUNT.bag == 2 and CHD_CLIENT.CHD_FIELD_COUNT.bank == 0)
assert(CHD_CLIENT.CHD_SCHEMA_VERSION == 1 and CHD_CLIENT.CHD_CAPTURE.selected.bag)
assert(CHD_ACCOUNT_INDEX['Realm A'].Example.captured_at == 12345)
assert(CHD_ACCOUNT_DUMPS['Realm A'].Example.CHD_ERRORS.spell)
CHD_CLIENT.bag[1][1].I = 99
assert(CHD_ACCOUNT_DUMPS['Realm A'].Example.bag[1][1].I == 1)
realm = 'Realm B'
d:StoreAccountDump('second character dump')
assert(CHD_ACCOUNT_DUMPS['Realm B'].Example == 'second character dump')
d:StoreAccountDump('older dump', true)
assert(CHD_ACCOUNT_DUMPS['Realm B'].Example == 'second character dump')
realm = 'Realm A'

local checked
chardumps.mainFrame.entitiesData = {bank = {checkbox = {
  SetChecked = function(_, value) checked = value end,
  GetChecked = function() return false end}}}
chardumps.mainFrame:SetEntityChecked('bank', false)
assert(checked == false)
chardumps.mainFrame:OnEvent('BANKFRAME_OPENED')
assert(d.dynamicDump.bank.mainbank[40].I == 5)
chardumps.mainFrame.entitiesData.bank.checkbox.GetChecked = function() return true end
local getBankData = d.GetBankData
d.GetBankData = function() error('bank still loading') end
chardumps.mainFrame:OnEvent('BANKFRAME_OPENED')
assert(d.dynamicDump.bank.mainbank[40].I == 5)
assert(chardumps.captureStatus:Get('bank') == 'failed')
d.GetBankData = getBankData
GetInventoryItemLink = function(_, slot)
  if slot == 1 then return '|Hitem:17:0:0:0:0:0:0:-7|h[item]|h' end
end
GetInventoryItemCount = function() return 1 end
GetInventoryItemDurability = function() return 43, 70 end
GetContainerNumSlots = function(bag) return bag == 0 and 1 or 0 end
GetContainerItemLink = function(bag, slot)
  if bag == 0 and slot == 1 then return '|Hitem:18:0:0:0:0:0:0:-8|h[item]|h' end
end
GetContainerItemInfo = function() return 'icon', 2, false, 3 end
GetContainerItemDurability = function() return 15, 20 end
local inventory = d:GetInventoryData()
assert(inventory[1].durability == 43 and inventory[1].max_durability == 70)
assert(inventory[24].quality == 3 and inventory[24].durability == 15)
assert(string.find(inventory[24].link, ':-8', 1, true))
assert(d:Dump({entities = {inventory = true}}))
assert(CHD_CLIENT.inventory[40] == nil) -- Unchecked bank data must not leak via inventory.
NUM_BAG_SLOTS = 1
GetContainerNumSlots = function() return 1 end
GetContainerItemLink = function() return nil end
assert(not pcall(getBagData)) -- Occupied slot with no link is not a successful scan.
time = function() return 12345 end
chardumps.mainFrame:OnEvent('TIME_PLAYED_MSG', 5000, 400)
assert(d.playedTime.total_seconds == 5000 and d.playedTime.level_seconds == 400)
assert(d.playedTime.collected_at == 12345)
UnitClass = function() return 'Warrior', 'WARRIOR' end
UnitRace = function() return 'Human', 'HUMAN' end
UnitLevel = function() return 80 end
UnitSex = function() return 2 end
GetPVPLifetimeStats = function() return 0 end
GetMoney = function() return 42 end
UnitHealth = function() return 100 end
UnitMana = function() return 0 end
d.GetPvpCurrency = function() return {honor = 0, ap = 0, cp = 0} end
local player = d:GetPlayerData()
assert(player.playtime.total_seconds == 5000 and player.playtime.level_seconds == 400)
d.playedTime.total_seconds = 6000
assert(player.playtime.total_seconds == 5000)

-- Load option accessors without creating the actual WoW UI.
local file = assert(io.open('chardumps.lua', 'r'))
local source = file:read('*a'); file:close()
source = source:gsub('chardumps:Init%(%);%s*$', '')
assert(loadstring(source))()
CHD_ACCOUNT_OPTIONS = {Example = {dynamicData = {bank = {value = 7}}}}
local migrated = chardumps:GetPlayerOptions()
assert(migrated.dynamicData.bank.value == 7)
migrated.dynamicData.bank.value = 8
assert(CHD_ACCOUNT_OPTIONS.Example.dynamicData.bank.value == 7)
realm = 'Realm B'
assert(next(chardumps:GetPlayerOptions()) == nil)

CHD_CLIENT = 'previous dump'
character = 'New Character'
chardumps.mainFrame.ApplyOptions = function() end
chardumps.mainFrame:OnVariablesLoaded()
assert(CHD_CLIENT == 'previous dump')
assert(CHD_ACCOUNT_DUMPS['Realm B']['New Character'] == 'previous dump')
print('capture tests passed')
