-- Exercise the overview text and frame setup with a minimal client API mock.
time = function() return 1700000000 end
date = os.date
UnitName = function() return 'Tester' end
GetRealmName = function() return 'Realm' end
local Frame = {}
Frame.__index = function(_, name)
  return Frame[name] or function() end
end
function Frame:CreateFontString() return setmetatable({}, Frame) end
function Frame:GetFrameLevel() return 1 end
function Frame:AddMessage(message) self.lines = self.lines or {}; table.insert(self.lines, message) end
function Frame:Clear() self.lines = {} end
CreateFrame = function(_, name) return setmetatable({name = name}, Frame) end
chardumps = {widgets = {
  GetBackdrop = function() return {} end,
  genFrameName = function() return 'chdOverviewTest' end,
  CreateButton = function(_, parent)
    assert(parent.name, 'button parent must have a name')
    return setmetatable({}, Frame)
  end,
}}
dofile('capture_status.lua')
dofile('main_frame.lua')
local ui = chardumps.mainFrame
ui.frame = setmetatable({}, Frame)
ui.entitiesData = {bank = {checkbox = {GetChecked = function() return true end}}}
chardumps.captureStatus:Mark('bank', true)
CHD_ACCOUNT_DUMPS = {Realm = {Tester = 'base64'}}
CHD_ACCOUNT_INDEX = {Realm = {Tester = {captured_at = time(), selected = {bank = true},
  collection = chardumps.captureStatus:Snapshot(), errors = {}}}}
CHD_GUILD_BANKS = {Realm = {Guild = {observed_at = time(), tab_count = 2,
  tabs = {[1] = {observed_at = time()}},
  permissions = {[1] = {can_view = true}, [2] = {can_view = false}}}}}
ui:ShowOverview()
local text = table.concat(ui.overview.textFrame.lines, '\n')
assert(string.find(text, 'Personal bank: collected', 1, true))
assert(string.find(text, 'Tester - Realm', 1, true))
assert(string.find(text, 'Tab 2: not observed, not viewable', 1, true))
print('overview mock tests passed')
