local chardumps = chardumps;
local guildBank = {isOpen = false};

function guildBank:CaptureCurrentTab()
  if not self.isOpen then return false, "Open the guild bank first." end
  local guild = GetGuildInfo("player");
  local realm = GetRealmName();
  local tab = GetCurrentGuildBankTab();
  if not guild or not realm or not tab or tab < 1 then return false, "No guild bank tab is selected." end
  local name, icon, canView = GetGuildBankTabInfo(tab);
  if not canView or canView == 0 then return false, "The selected tab is not viewable." end

  -- Only consume the data delivered for the tab the player opened. Do not
  -- issue QueryGuildBankTab or change tabs on the player's behalf.
  local slots = {};
  for slot = 1, (MAX_GUILDBANK_SLOTS_PER_TAB or 98) do
    local texture, count, _, _, quality = GetGuildBankItemInfo(tab, slot);
    local link = GetGuildBankItemLink(tab, slot);
    if (texture and not link) or (link and not count) then
      error("Guild bank tab contains item data that has not finished loading");
    end
    if link then
      local id = tonumber(string.match(link, "Hitem:(%d+)"));
      if not id then error("Guild bank item link could not be parsed") end
      slots[slot] = {I = id, N = count, link = link, quality = quality};
    end
  end

  CHD_GUILD_BANKS = CHD_GUILD_BANKS or {};
  CHD_GUILD_BANKS[realm] = CHD_GUILD_BANKS[realm] or {};
  local previous = CHD_GUILD_BANKS[realm][guild] or {};
  local bank = {tabs = {}, money_copper = previous.money_copper,
    money_observed_at = previous.money_observed_at};
  for oldTab, snapshot in pairs(previous.tabs or {}) do bank.tabs[oldTab] = snapshot end
  bank.tab_count = GetNumGuildBankTabs();
  bank.observed_by = UnitName("player");
  bank.observed_at = time();
  local money = GetGuildBankMoney();
  if type(money) == "number" then
    bank.money_copper = money;
    bank.money_observed_at = bank.observed_at;
  end
  bank.permissions = {};
  for i = 1, bank.tab_count do
    local tabName, tabIcon, visible = GetGuildBankTabInfo(i);
    local permission = {name = tabName, icon = tabIcon};
    if tabName then permission.can_view = visible and visible ~= 0 and true or false end
    bank.permissions[i] = permission;
  end
  bank.tabs[tab] = {name = name, icon = icon, slots = slots, observed_at = bank.observed_at,
    observed_by = bank.observed_by};
  CHD_GUILD_BANKS[realm][guild] = bank;
  chardumps.captureStatus:Mark("guildbank", true, guild .. " tab " .. tostring(tab));
  return true, "Recorded guild bank tab " .. tab .. " for " .. guild .. ".";
end

function guildBank:CaptureRequested()
  local ok, captured, message = pcall(function() return self:CaptureCurrentTab() end);
  if not ok then
    chardumps.captureStatus:Mark("guildbank", false, nil, tostring(captured));
    chardumps.log:Warning("Guild bank tab was not saved: " .. tostring(captured));
  elseif captured then
    chardumps.log:Message(message);
  else
    chardumps.captureStatus:Mark("guildbank", false, nil, message);
    chardumps.log:Warning(message);
  end
  return ok and captured;
end

chardumps.guildBank = guildBank;
