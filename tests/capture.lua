-- Run from the project root with Lua 5.1.
chardumps = {log = {Message = function() end, Error = function() end,
  Warning = function() end, Debug = function() end}}
chardumps.MAX_NUM_CONTINENT = 4
dofile('functions.lua')
dofile('entity_manager.lua')
dofile('encryption.lua')
dofile('b64.lua')
dofile('dumper.lua')
dofile('main_frame.lua')
assert(chardumps.encryption:toJson('a\rb\1') == '"a\\rb\\u0001"')
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
d.dynamicDump = {bank = {mainbank = {[40] = {I = 5}}}}
d.GetBagData = function() return {{{I = 1}, {I = 2}}} end
d.GetSpellData = function() error('test failure') end
local ok = d:Dump({entities = {bag = true, spell = true}})
assert(not ok and CHD_CLIENT.CHD_ERRORS.spell)
assert(CHD_CLIENT.CHD_FIELD_COUNT.bag == 2 and CHD_CLIENT.CHD_FIELD_COUNT.bank == 0)

local checked
chardumps.mainFrame.entitiesData = {bank = {checkbox = {
  SetChecked = function(_, value) checked = value end,
  GetChecked = function() return false end}}}
chardumps.mainFrame:SetEntityChecked('bank', false)
assert(checked == false)
chardumps.mainFrame:OnEvent('BANKFRAME_OPENED')
assert(d.dynamicDump.bank.mainbank[40].I == 5)

-- Load option accessors without creating the actual WoW UI.
local file = assert(io.open('chardumps.lua', 'r'))
local source = file:read('*a'); file:close()
source = source:gsub('chardumps:Init%(%);%s*$', '')
assert(loadstring(source))()
local realm = 'Realm A'
UnitName = function() return 'Example' end
GetRealmName = function() return realm end
CHD_ACCOUNT_OPTIONS = {Example = {dynamicData = {bank = {value = 7}}}}
local migrated = chardumps:GetPlayerOptions()
assert(migrated.dynamicData.bank.value == 7)
migrated.dynamicData.bank.value = 8
assert(CHD_ACCOUNT_OPTIONS.Example.dynamicData.bank.value == 7)
realm = 'Realm B'
assert(next(chardumps:GetPlayerOptions()) == nil)

CHD_CLIENT = 'previous dump'
chardumps.mainFrame.ApplyOptions = function() end
chardumps.mainFrame:OnVariablesLoaded()
assert(CHD_CLIENT == 'previous dump')
print('capture tests passed')
