-- Load the actual TOC in a minimal WoW UI mock; this does not validate layout.
local Frame = {}
Frame.__index = function(_, name) return Frame[name] or function() end end
function Frame:GetName() return self.name end
function Frame:GetFrameLevel() return 1 end
function Frame:GetFontString() return setmetatable({}, Frame) end
function Frame:CreateFontString() return setmetatable({}, Frame) end
function Frame:CreateTitleRegion() return setmetatable({}, Frame) end
function Frame:SetScript(name, fn) self.scripts = rawget(self, 'scripts') or {}; self.scripts[name] = fn end
function Frame:SetChecked(value) self.checked = value end
function Frame:GetChecked() return rawget(self, 'checked') end
function Frame:Show() self.visible = true end
function Frame:Hide() self.visible = false end
function Frame:IsVisible() return rawget(self, 'visible') end
function Frame:AddMessage(value) self.messages = rawget(self, 'messages') or {}; table.insert(self.messages, value) end
function Frame:Clear() self.messages = {} end
local created = {}
function CreateFrame(_, name)
  if name then
    assert(not created[name], 'duplicate named frame ' .. name)
    created[name] = true
  end
  return setmetatable({name = name}, Frame)
end
UIParent = setmetatable({name = 'UIParent'}, Frame)
function getglobal(name) return _G[name] end
GetBuildInfo = function() return '3.3.5', '12340' end
GetLocale = function() return 'enUS' end
UnitName = function() return 'Tester' end
GetRealmName = function() return 'Test Realm' end
time = function() return 1700000000 end
date = os.date
SlashCmdList = {}
for line in io.lines('chardumps.toc') do
  if line ~= '' and string.sub(line, 1, 1) ~= '#' then
    dofile((string.gsub(line, '\\', '/')))
  end
end
local ui = chardumps.mainFrame
assert(ui.frame and ui.frame.scripts.OnEvent)
ui.frame.scripts.OnEvent(ui.frame, 'VARIABLES_LOADED')
SlashCmdList.CHARDUMPS('overview')
assert(ui.overview and ui.overview.visible and #ui.overview.textFrame.messages > 0)
assert(created[ui.overview.name], 'overview needs a named parent for its button')
chardumps.dumper.GetPlayerData = function() return {name = 'Tester'} end
chardumps.dumper.GetGlobalData = function() return {realm = 'Test Realm'} end
ui.UpdateEntityView = function() end
local warnings = {}
chardumps.log.Warning = function(_, message) table.insert(warnings, message) end
ui.frame.scripts.OnEvent(ui.frame, 'TIME_PLAYED_MSG', 500, 50)
ui:OnDumpClick()
assert(string.find(table.concat(warnings, '\n'), 'Not selected: ', 1, true))
assert(string.find(table.concat(warnings, '\n'), 'Inventory', 1, true))
assert(string.find(table.concat(warnings, '\n'), 'Bags', 1, true))
assert(type(CHD_CLIENT) == 'string' and #CHD_CLIENT > 0)
assert(CHD_ACCOUNT_DUMPS['Test Realm'].Tester == CHD_CLIENT)
assert(CHD_ACCOUNT_INDEX['Test Realm'].Tester.collection.playtime.state == 'collected')
ui:OnPlayerLeavingWorld()
assert(CHD_ACCOUNT_OPTIONS['Test Realm - Tester'].playedTime.total_seconds == 500)
print('TOC load and overview integration tests passed')
