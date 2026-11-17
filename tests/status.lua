-- Run from the project root with Lua 5.1.
local now = 1700000000
time = function() return now end
UnitName = function() return 'Tester' end
GetRealmName = function() return 'Test Realm' end
chardumps = {log = {Warning = function() end, Message = function() end}}
dofile('capture_status.lua')
dofile('guild_bank.lua')
local s, g = chardumps.captureStatus, chardumps.guildBank
s:Load(nil, {bank = {}, quest = {}})
assert(s:Get('bank') == 'unknown')
assert(s:Get('playtime') == 'not collected')
s:Mark('bank', true)
assert(s:Get('bank') == 'collected')
local saved = s:Snapshot()
s:Load(saved)
assert(s:Get('bank') == 'previously collected')
s:Mark('bank', false, nil, 'failed to load')
local state, rec = s:Get('bank')
assert(state == 'failed' and rec.reason == 'failed to load' and rec.last_success_at == now)
s:Mark('skillspell', true, 'Alchemy')
assert(s:Snapshot().skillspell.details.Alchemy == now)

local selectedTab, viewable, pending = 1, true, false
GetGuildInfo = function() return 'Test Guild' end
GetCurrentGuildBankTab = function() return selectedTab end
GetNumGuildBankTabs = function() return 2 end
GetGuildBankTabInfo = function(tab) return 'Tab ' .. tab, 'icon', viewable end
GetGuildBankMoney = function() return 123 end
GetGuildBankItemInfo = function(tab, slot)
  if slot == 1 then return 'icon', 3, false, false, 2 end
end
GetGuildBankItemLink = function(tab, slot)
  if slot == 1 and not pending then return '|Hitem:123:0:0:0:0|h[item]|h' end
end
MAX_GUILDBANK_SLOTS_PER_TAB = 2
g:CaptureRequested()
assert(CHD_GUILD_BANKS == nil) -- Closed bank cannot be observed.
g.isOpen = true
g:CaptureRequested()
local bank = CHD_GUILD_BANKS['Test Realm']['Test Guild']
assert(bank.tabs[1].slots[1].I == 123 and bank.tabs[1].slots[1].N == 3)
assert(bank.money_copper == 123 and bank.tabs[2] == nil)
pending = true
now = now + 1
g:CaptureRequested()
assert(bank.tabs[1].observed_at == 1700000000) -- Failure preserves old snapshot.
assert(s:Get('guildbank') == 'failed')
pending = false
viewable = false
selectedTab = 2
g:CaptureRequested()
assert(bank.tabs[2] == nil) -- An inaccessible tab is not an empty tab.
print('status and guild-bank tests passed')
