local chardumps = chardumps;

local mainFrame = {
  entitiesData = {
  -- entityName = {
  -- checkbox (Yes/No),
  -- Data View (Frame),
  -- Delete Button (Button)
  -- Active Button (Button)
  -- Press dump button font
  -- }
  },
  captionHeight = 30,
  bttomPanelHeight = 40,
  defaultWidth = 600,
  defaultHeight = 440,
  defaultEntityWidth = 200,
  dataFrame = {
    defaultTop = 30,
    defaultLeft = 210,
    defaultWidth = 400,
    defaultHeight = 380,
  },
};

function mainFrame:CreateEntityFrame(name, parent)
  local frameName = chardumps.widgets:genFrameName();
  local frame = CreateFrame("ScrollingMessageFrame", frameName, parent);
  frame:ClearAllPoints();
  frame:SetPoint("TOPRIGHT", -10, -self.dataFrame.defaultTop);
  frame:SetWidth(self.dataFrame.defaultWidth);
  frame:SetHeight(self.dataFrame.defaultHeight);
  frame:SetBackdrop(chardumps.widgets:GetBackdrop());
  frame:SetFontObject("GameFontNormal");
  frame:Hide();
  frame.chdEntityName = name;

  return frame;
end

function mainFrame:RegisterWorkEvents(frame)
  if not frame then
    frame = self.frame;
  end
  local events = {
    "TAXIMAP_OPENED", "VARIABLES_LOADED", "BANKFRAME_OPENED", "PLAYER_LEAVING_WORLD",
    "TRADE_SKILL_SHOW", "QUEST_DETAIL", "QUEST_PROGRESS",
    "QUEST_QUERY_COMPLETE", "ADDON_LOADED", "PLAYER_LOGOUT", -- UNIT_QUEST_LOG_CHANGED
    "QUEST_TURNED_IN", "TIME_PLAYED_MSG", "GUILDBANKFRAME_OPENED", "GUILDBANKFRAME_CLOSED",
  }
  frame:UnregisterAllEvents();
  for _, name in pairs(events) do
    frame:RegisterEvent(name);
  end
end

function mainFrame:Init()
  local L = chardumps:GetLocale();
  local widgets = chardumps.widgets;
  local frame = CreateFrame("Frame", widgets:GetFrameName("frmMain"), UIParent);

  frame:EnableMouse(true);
  frame:SetMovable(true);
  frame:SetResizable(true);
  frame:ClearAllPoints();
  frame:SetPoint("CENTER", UIParent);
  frame:SetWidth(self.defaultWidth);
  frame:SetHeight(self.defaultHeight);
  frame:SetFrameStrata("DIALOG");
  frame:SetScript("OnEvent", self.OnEvent);
  frame:SetBackdrop(chardumps.widgets:GetBackdrop());
  frame:SetFrameStrata("DIALOG");
  frame:Show();
  local titleRegion = frame:CreateTitleRegion();
  titleRegion:SetAllPoints();

  local str = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  str:SetPoint("CENTER", frame, 0, 0);
  str:SetPoint("TOP", frame, 0, -5);
  str:SetTextColor(1.0, 1.0, 0.0, 1.0);
  local addonTitle = L.AddonName .. " " .. L.Version .. " - http://wowtransfer.com";
  str:SetText(addonTitle);


  local btnW = widgets.btnWidth;
  local frameMin = CreateFrame("Frame", widgets:GetFrameName("minFrame", frame:GetName()), frame);
  frameMin:ClearAllPoints();
  frameMin:SetPoint("TOPRIGHT", frame, 0, 0);
  frameMin:SetWidth(5 + 5 + btnW*3 + 3*3 + 5);
  frameMin:SetHeight(5 + widgets.btnHeight + 5);
  frameMin:Show();

  local btn;
  btn = widgets:CreateButton(frameMin);
  btn:SetText("x");
  btn:SetScript("OnClick", self.OnHideClick);
  btn:ClearAllPoints();
  btn:SetPoint("CENTER", 0, 0);
  btn:SetPoint("RIGHT", -11, 0);
  widgets:SetTooltip(btn, L.ttbtnHide);

  btn = widgets:CreateButton(frameMin);
  btn:SetText("_");
  btn:SetScript("OnClick", self.OnMinimizeClick);
  btn:ClearAllPoints();
  btn:SetPoint("CENTER", 0, 0);
  btn:SetPoint("RIGHT", -14 - btnW, 0);
  widgets:SetTooltip(btn, L.ttbtnMinimize);

  btn = widgets:CreateButton(frame, {name = "btnDump", cx = 100});
  btn:ClearAllPoints();
  btn:SetScript("OnClick", self.OnDumpClick);
  btn:SetPoint("BOTTOMRIGHT", -10, 10);

  local btnOverview = widgets:CreateButton(frame, {cx = 100, cy = 20, text = "Overview"});
  btnOverview:SetPoint("BOTTOMLEFT", 10, 10);
  btnOverview:SetScript("OnClick", function() mainFrame:ShowOverview() end);

  self.btnSave = widgets:CreateButton(frame, {name = "btnReload", cx = 100});
  self.btnSave:ClearAllPoints();
  self.btnSave:SetScript("OnClick", self.OnSaveClick);
  self.btnSave:SetPoint("BOTTOMRIGHT", -10 - 5 - 100, 10);
  self.btnSave:Disable();

  self.chbEvents = widgets:CreateCheckbox(frame, {name = "chbEvents", cx = 14, cy = 14, text = "Events"});
  self.chbEvents:ClearAllPoints();
  self.chbEvents:SetPoint("BOTTOMRIGHT", -10 - 5 - 370, 10);
  self.chbEvents:SetScript("OnClick", function ()
    if mainFrame.chbEvents:GetChecked() then
      mainFrame.frame:RegisterAllEvents();
    else
      mainFrame:RegisterWorkEvents();
    end
  end);

  -- Checkbox list

  -- checkbox
  -- button
  -- text

  local y = 30;
  local x = 0;
  local entities = chardumps.entityManager:GetEntities();

  local btnDeleteAllTooltip = L.deleteAll;
  local btn = widgets:CreateButton(frame, {x = 10, y = -10, cx = 12, cy = 12, tooltipTitle = btnDeleteAllTooltip});
  btn:SetScript("OnClick", self.OnDeleteAllClick);
  local chbAllTooltip = L.ttchbAll;
  local chbAll = widgets:CreateCheckbox(frame, {x = 28, y = -10, cx = 14, cy = 14,
    tooltipTitle = chbAllTooltip, withoutText = true});
  chbAll:SetScript("OnClick", self.OnChbAllClick);
  local selectAllLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  selectAllLabel:SetPoint("TOPLEFT", 45, -10);
  selectAllLabel:SetText(L.SelectAllCategories or "Select all");

  -- Create entity's structure
  for _, name in ipairs(chardumps.entityManager:GetNames()) do
    local entity = entities[name];
    local deleteButton;
    if not entity.always and not entity.disable then
      deleteButton = widgets:CreateButton(frame, {x = 10, y = -y, cx = 12, cy = 12, tooltipTitle = L.Delete});
      deleteButton.chdEntityName = name;
      deleteButton:SetScript("OnClick", function(self)
        mainFrame:DeleteEntityData(self.chdEntityName);
      end)
    end

    local text = L[name];

    local btnActive = widgets:CreateButton(frame, {x = 42, y = -y, cx = 150, cy = 14, text = text});
    btnActive.chdEntityName = name;
    local btnActiveFont = btnActive:GetFontString();
    btnActiveFont:SetJustifyH("LEFT"); -- TODO: do not work
    btnActiveFont:SetTextColor(1, 1, 1);
    btnActive:SetScript("OnClick", function(self)
      mainFrame:SetActiveDataFrame(self.chdEntityName);
    end);

    local chb = widgets:CreateCheckbox(frame, {x = 28, y = -y, cx = 14, cy = 14, tooltipTitle = text, withoutText = true});
    chb.chdEntityName = name;
    if entity.disable then
      chb:SetChecked(false);
      chb:Disable();
      chb:Hide();
      btnActiveFont:SetTextColor(0.5, 0.5, 0.5);
    elseif entity.always then
      chb:SetChecked(true);
      chb:Disable();
    end

    chb:SetScript("OnClick", function(self)
      mainFrame:SetActiveDataFrame(self.chdEntityName);
    end);

    local entityData = {};
    entityData.checkbox = chb;
    entityData.deleteButton = deleteButton;
    entityData.dataFrame = self:CreateEntityFrame(name, frame);
    entityData.activeButton = btnActive;
    self.entitiesData[name] = entityData;

    y = y + 14;
  end
  self:CreateEntityWidgets(frame);
  self:SetActiveDataFrame();
  self:RegisterWorkEvents(frame);

  self.frameMin = frameMin;
  self.frame = frame;
end

function mainFrame:CreateEntityWidgets(frame)
  local L = chardumps:GetLocale();

  for name, data in pairs(self.entitiesData) do
    local entityFrame = data.dataFrame;
    local font = entityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    font:SetPoint("TOPLEFT", 50, -5);
    font:SetText(L[name]);

    local pressDumpButtonWarning = entityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    pressDumpButtonWarning:SetPoint("TOPLEFT", 10, -30);
    pressDumpButtonWarning:SetText(L["Press \"Dump\" button"]);
    pressDumpButtonWarning:SetTextColor(chardumps.config:GetWarningColor());
    data.pressDumpBtnText = pressDumpButtonWarning;
  end

  local top = 25;

  local questData = self.entitiesData["quest"];
  if questData then
    local btnQueryQuest = chardumps.widgets:CreateButton(questData.dataFrame, {x = 5, y = -top, cx = 150, name = "btnQuestQuery"});
    btnQueryQuest:SetScript("OnClick", function()
      if type(QueryQuestsCompleted) == "function" then
        QueryQuestsCompleted();
      else
        self:OnQuestQueryComplete();
      end
    end);
  end
end

function mainFrame:SetActiveDataFrame(name)
  local entities = chardumps.entityManager:GetEntities();
  if name == nil then
    name = "player";
  end
  local entity = entities[name];
  if not entity then
    return
  end

  if self.activeDataDrame ~= nil then
    self.activeDataDrame:Hide();
    local name = self.activeDataDrame.chdEntityName;
    local entity = entities[name];
    local activeButton = self.entitiesData[name].activeButton;
    if not entity.disable and activeButton then
      activeButton:GetFontString():SetTextColor(1, 1, 1);
    end
  end
  local frame = self.entitiesData[name].dataFrame;
  frame:Show();
  local activeButton = self.entitiesData[name].activeButton;
  if not entity.disable and activeButton then
    activeButton:GetFontString():SetTextColor(1, 1, 0);
  end

  self.activeDataDrame = frame;
end

function mainFrame:UpdateEntityText(name, count)
  local data = self.entitiesData[name];
  if data then
    local entity = chardumps.entityManager:GetEntity(name);
    local chb = data.checkbox;
    local activeButton = data.activeButton;
    local disable = entity and entity.disable;
    if activeButton and not disable then
      local L = chardumps:GetLocale();
      local entityName = L[name];
      count = count or 0;
      entityName = entityName .. " (" .. count .. ")";
      activeButton:SetText(entityName);
    end
  end
end

function mainFrame:UpdateEntityView(name)
  local data = self.entitiesData[name];
  if data then
    local entityFrame = data.dataFrame;
    local functionName = "Update" .. chardumps:Ucfirst(name) .. "View";
    local views = chardumps.entityViews;
    local entityViewFun = views[functionName];
    if type(entityViewFun) == "function" and entityFrame then
      views[functionName](views, entityFrame);
    end
  end
end

local function formatTime(stamp)
  if type(stamp) ~= "number" then return "time unknown" end
  return date("%Y-%m-%d %H:%M", stamp);
end

local function sortedKeys(tbl)
  local keys = {};
  for key in pairs(tbl or {}) do table.insert(keys, key) end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end);
  return keys;
end

function mainFrame:ShowOverview()
  if not self.overview then
    local window = CreateFrame("Frame", chardumps.widgets:genFrameName(), self.frame);
    window:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -28);
    window:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -10, 36);
    window:SetBackdrop(chardumps.widgets:GetBackdrop());
    window:SetFrameLevel(self.frame:GetFrameLevel() + 5);
    window:EnableMouse(true);
    local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    title:SetPoint("TOPLEFT", 12, -10);
    title:SetText("Collection and account overview");
    local close = chardumps.widgets:CreateButton(window, {cx = 55, cy = 20, text = "Close"});
    close:SetPoint("TOPRIGHT", -8, -6);
    close:SetScript("OnClick", function() window:Hide() end);
    local textFrame = CreateFrame("ScrollingMessageFrame", nil, window);
    textFrame:SetPoint("TOPLEFT", 10, -36);
    textFrame:SetPoint("BOTTOMRIGHT", -10, 8);
    textFrame:SetFontObject("GameFontHighlightSmall");
    textFrame:SetJustifyH("LEFT");
    textFrame:SetMaxLines(1000);
    textFrame:SetFading(false);
    textFrame:EnableMouseWheel(true);
    textFrame:SetScript("OnMouseWheel", function(frame, delta)
      if delta > 0 then frame:ScrollUp() else frame:ScrollDown() end
    end);
    window.textFrame = textFrame;
    self.overview = window;
  end

  local textFrame = self.overview.textFrame;
  textFrame:Clear();
  local function line(text) textFrame:AddMessage(text, 1, 1, 1) end
  line("CURRENT CHARACTER: " .. (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?"));
  line("A collected status means observed, not verified complete. Mouse wheel scrolls.");
  local labels = {{"bank", "Personal bank"}, {"quest", "Completed quests"},
    {"skillspell", "Profession recipes"}, {"taxi", "Flight paths"},
    {"playtime", "Playtime (/played)"}, {"guildbank", "Guild bank tabs"}};
  for _, entry in ipairs(labels) do
    local name, label = entry[1], entry[2];
    local state, record = chardumps.captureStatus:Get(name);
    local enabled = self.entitiesData[name] and self:IsEntityChecked(name);
    local selection = self.entitiesData[name] and (enabled and " [included]" or " [unchecked]") or "";
    local stamp = record and record.at and (" - " .. formatTime(record.at)) or "";
    line(label .. ": " .. state .. stamp .. selection);
    if record and record.reason then line("  Last error: " .. record.reason) end
    if record and record.state == "failed" and record.last_success_at then
      line("  Previous observation: " .. formatTime(record.last_success_at) .. " (may be stale)");
    end
    if record and record.details then
      local details = {};
      for _, key in ipairs(sortedKeys(record.details)) do
        table.insert(details, tostring(key) .. " (" .. formatTime(record.details[key]) .. ")");
      end
      line("  Observed: " .. table.concat(details, ", "));
    end
  end
  line("Open bank and each profession; query quests; visit flight masters by continent; use /played.");
  line("Guild bank: open a tab, wait for it to load, then type /chardumps guildbank.");
  line(" ");
  line("ACCOUNT SNAPSHOTS (Save or log out to write the file)");
  local found = false;
  for _, realm in ipairs(sortedKeys(CHD_ACCOUNT_DUMPS)) do
    for _, character in ipairs(sortedKeys(CHD_ACCOUNT_DUMPS[realm])) do
      found = true;
      local index = CHD_ACCOUNT_INDEX and CHD_ACCOUNT_INDEX[realm] and CHD_ACCOUNT_INDEX[realm][character];
      line(character .. " - " .. realm .. ": " .. (index and formatTime(index.captured_at) or "legacy, time unknown"));
      if index then
        local missing = {};
        for _, entry in ipairs(labels) do
          local key = entry[1];
          if key ~= "guildbank" then
            local status = index.collection and index.collection[key];
            if key ~= "playtime" and not (index.selected and index.selected[key]) then
              table.insert(missing, entry[2] .. " unchecked");
            elseif not status or status.state ~= "collected" then
              table.insert(missing, entry[2] .. " " .. (status and status.state or "not collected"));
            end
          end
        end
        for _, entry in ipairs({{"achievement", "Achievements"}, {"criterias", "Criteria"},
          {"reputation", "Reputation"}, {"inventory", "Equipment/backpack"}, {"bag", "Bags"},
          {"spell", "Spells"}, {"talent", "Talents"}, {"skill", "Skills"}}) do
          if not (index.selected and index.selected[entry[1]]) then
            table.insert(missing, entry[2] .. " unchecked");
          end
        end
        if next(index.errors or {}) then
          table.insert(missing, "failed: " .. table.concat(sortedKeys(index.errors), ", "));
        end
        if #missing > 0 then line("  Review: " .. table.concat(missing, "; ")) end
      end
    end
  end
  if not found then line("No character snapshots yet.") end
  line(" ");
  line("GUILD BANK SNAPSHOTS");
  local guildFound = false;
  for _, realm in ipairs(sortedKeys(CHD_GUILD_BANKS)) do
    for _, guild in ipairs(sortedKeys(CHD_GUILD_BANKS[realm])) do
      guildFound = true;
      local bank = CHD_GUILD_BANKS[realm][guild];
      line(guild .. " - " .. realm .. ": last observed " .. formatTime(bank.observed_at));
      for tab = 1, (bank.tab_count or 0) do
        local observed = bank.tabs and bank.tabs[tab];
        local permission = bank.permissions and bank.permissions[tab];
        local description = observed and ("observed " .. formatTime(observed.observed_at)) or "not observed";
        if permission and permission.can_view == false then description = description .. ", not viewable by last character" end
        line("  Tab " .. tab .. ": " .. description);
      end
    end
  end
  if not guildFound then line("No guild-bank tabs observed yet.") end
  textFrame:ScrollToTop();
  self.overview:Show();
end

function mainFrame:OnHideClick()
  mainFrame.Hide();
end

function mainFrame:Hide()
  mainFrame.frameMin:Hide();
  mainFrame.frame:Hide();
end

function mainFrame:Show()
  mainFrame.frameMin:SetBackdrop(nil);
  mainFrame.frameMin:SetParent(mainFrame.frame);
  mainFrame.frameMin:Show();
  mainFrame.frame:Show();
end

function mainFrame:OnDumpClick()
  local L = chardumps:GetLocale();

  local options = chardumps.options;
  options:ClearForDump();
  -- read options
  for name, data in pairs(mainFrame.entitiesData) do
    if (data.checkbox:GetChecked()) then
      data.pressDumpBtnText:Hide();
      options:AddEntityForDump(name);
    end
  end

  local dumpOption = options:GetOptionsForDump();
  local missingItems = {};
  if not dumpOption.entities.inventory then table.insert(missingItems, L.inventory or "Inventory") end
  if not dumpOption.entities.bag then table.insert(missingItems, L.bag or "Bags") end
  if #missingItems > 0 then
    chardumps.log:Warning(string.format(L.ItemsNotSelected or
      "Not selected: %s. Check the squares beside these categories and press Dump again.",
      table.concat(missingItems, ", ")));
  end
  local complete = chardumps.dumper:Dump(dumpOption);

  mainFrame.btnSave:Enable();
  if complete then
    chardumps.log:Message(L.CreatedDump);
  else
    chardumps.log:Warning("Dump is incomplete. Failed categories are listed above and in CHD_ERRORS.");
  end
  chardumps.log:Warning("Bank, recipes, completed quests and flight paths require prior in-game collection; cached data may be incomplete or stale.");
  if not chardumps.dumper.playedTime then
    chardumps.log:Warning("Playtime has not been received. Use /played, wait for the response, then dump again.");
  end
  chardumps.log:Message("Save or log out to write the account dump to WTF/Account/<account>/SavedVariables/chardumps.lua.");
end

function mainFrame:OnSaveClick()
  ReloadUI();
end

function mainFrame:DeleteEntityData(entityName)
  local entities = chardumps.entityManager:GetEntities();
  local entity = entities[entityName];
  if entity then
    if entity.dynamic then
      local L = chardumps:GetLocale();
      chardumps.widgets:ShowMessageBox(L.areyousure, function()
        chardumps.dumper:DeleteEntityData(entityName);
      end);
    else
      chardumps.dumper:DeleteEntityData(entityName);
    end
  end
end

function mainFrame:OnDeleteAllClick()
  local L = chardumps:GetLocale();
  chardumps.widgets:ShowMessageBox(L.areyousure, function()
    chardumps.dumper:Clear();
  end);
end

function mainFrame:OnChbAllClick()
  local checked = self:GetChecked();
  local entities = chardumps.entityManager:GetEntities();
  for name, data in pairs(mainFrame.entitiesData) do
    local entity = entities[name];
    local always = entity and entity.always;
    local disable = entity and entity.disable;
    if not(always or disable) then
      data.checkbox:SetChecked(checked);
    end
  end
end

function mainFrame:OnMinimizeClick()
  local frame = mainFrame.frame;
  local frameMin = mainFrame.frameMin;

  if frame:IsVisible() then
    frameMin:SetBackdrop(chardumps.widgets:GetBackdrop());
    frameMin:SetParent(UIParent);
    frame:Hide();
    chardumps.options.minimize = true;
  else
    frameMin:SetBackdrop(nil);
    frameMin:SetParent(frame);
    frame:Show();
    chardumps.options.minimize = false;
  end
end

---
-- @return #boolean
function mainFrame:IsEntityChecked(name)
  local data = self.entitiesData[name];
  if data then
    return data.checkbox:GetChecked();
  end
  return false;
end

---
-- @return #boolean
function mainFrame:SetEntityChecked(name, value)
  local data = self.entitiesData[name];
  if data then
    if value == nil then value = true end
    data.checkbox:SetChecked(value);
  end
end

function mainFrame:OnEvent(event, ...)
  chardumps.log:Debug(event);
  if "TIME_PLAYED_MSG" == event then
    local total, level = ...;
    if type(total) == "number" and type(level) == "number" then
      chardumps.dumper.playedTime = {total_seconds = total, level_seconds = level, collected_at = time()};
      chardumps.captureStatus:Mark("playtime", true);
    end
  elseif "GUILDBANKFRAME_OPENED" == event then
    chardumps.guildBank.isOpen = true;
  elseif "GUILDBANKFRAME_CLOSED" == event then
    chardumps.guildBank.isOpen = false;
  elseif "BANKFRAME_OPENED" == event then
    if mainFrame:IsEntityChecked("bank") then
      local ok, bankData = pcall(chardumps.dumper.GetBankData);
      if ok then
        chardumps.dumper:SetDynamicData("bank", bankData);
        chardumps.captureStatus:Mark("bank", true);
      else
        chardumps.captureStatus:Mark("bank", false, nil, tostring(bankData));
        chardumps.log:Error("Failed to capture bank: " .. tostring(bankData));
      end
    end
    local count = chardumps.dumper:GetBankItemsCount();
    mainFrame:UpdateEntityText("bank", count);
  elseif "PLAYER_LEAVING_WORLD" == event then
    mainFrame:OnPlayerLeavingWorld();
  elseif "TAXIMAP_OPENED" == event then
    mainFrame:TryCollection("taxi", function() mainFrame:OnTaximapOpened() end);
  elseif "ADDON_LOADED" == event then
    mainFrame:OnAddonLoaded(...);
  elseif "VARIABLES_LOADED" == event then
    mainFrame:OnVariablesLoaded();
  elseif "TRADE_SKILL_SHOW" == event then
    mainFrame:TryCollection("skillspell", function() mainFrame:OnTradeSkillShow() end);
  elseif "QUEST_TURNED_IN" == event then
    if chardumps:GetPatchVersion() <= 3 then
      return
    end
    local L = chardumps:GetLocale();
    local questId = GetQuestID();
    chardumps.log:Message(L.Quest .. " (ID = " .. questId .. ") \124cFF00FF00 " .. L.QuestCompleted .. "\r");
  elseif "QUEST_DETAIL" == event or "QUEST_PROGRESS" == event then
    if chardumps:GetPatchVersion() <= 3 then
      return
    end
    local L = chardumps:GetLocale();
    local questIds = chardumps.dumper:GetDynamicData("quest");
    local questId = GetQuestID();
    local s = L.Quest .. " (ID = " .. questId .. ")";
    if questIds[questId] then
      s = s .. " \124cFF00FF00 " .. L.QuestWasCompleted  .. "\r";
    end
    chardumps.log:Message(s);
  elseif "QUEST_QUERY_COMPLETE" == event then
    mainFrame:TryCollection("quest", function() mainFrame:OnQuestQueryComplete() end);
  elseif "PLAYER_LOGOUT" == event then
    chardumps.log:Debug(event, ...);
  else
    chardumps.log:Debug(event, ...);
  end
end

function mainFrame:TryCollection(name, fn)
  local ok, err = pcall(fn);
  if not ok then
    chardumps.captureStatus:Mark(name, false, nil, tostring(err));
    chardumps.log:Error("Failed to collect " .. name .. ": " .. tostring(err));
  end
end

function mainFrame:ApplyOptions()
  local entities = chardumps.entityManager:GetEntities();
  local playerOptions = chardumps:GetPlayerOptions();
  playerOptions.entities = playerOptions.entities or {};

  for name, checked in pairs(playerOptions.entities) do
    if entities[name] and not entities[name].disable then
      self:SetEntityChecked(name, checked);
    end
  end
  chardumps.options:SetDebug(playerOptions.debug);
  if playerOptions.minimize then
    self:OnMinimizeClick();
  end
end

function mainFrame:SetDebug(value)
  if value then
    self.chbEvents:Show();
  else
    self.chbEvents:Hide();
  end
end

function mainFrame:OnQuestQueryComplete()
  local questIds = chardumps.dumper:GetQuestDataReal();
  local count = chardumps:GetTableLength(questIds);
  self:UpdateEntityText("quest", count);
  chardumps.captureStatus:Mark("quest", true);
end

---
-- Recipe filters hide entries from GetNumTradeSkills, so a filtered list
-- must not be stored as the full recipe list.
-- @return #string reason when a filter is active, otherwise nil
local function getActiveTradeSkillFilter()
  if type(GetTradeSkillItemNameFilter) == "function" then
    local text = GetTradeSkillItemNameFilter();
    if text and text ~= "" then return "the search box" end
  end
  local makeable = TradeSkillFrameAvailableFilterCheckButton;
  if makeable and makeable:GetChecked() then return "\"Have Materials\"" end
  -- Filter index 0 is "All"; it is 1 when nothing is filtered out.
  if type(GetTradeSkillSubClassFilter) == "function" and not GetTradeSkillSubClassFilter(0) then
    return "the subclass filter"
  end
  if type(GetTradeSkillInvSlotFilter) == "function" and not GetTradeSkillInvSlotFilter(0) then
    return "the slot filter"
  end
end

-- http://wowprogramming.com/docs/api_categories#tradeskill
function mainFrame:OnTradeSkillShow(flags)
  if not mainFrame:IsEntityChecked("skillspell") then
    return
  end

  local L = chardumps:GetLocale();
  -- Returns information about the current trade skill
  local tradeskillName, rank, maxLevel = GetTradeSkillLine();
  if (nil == tradeskillName or "UNKNOWN" == tradeskillName) then
    return
  end

  -- Another player's linked profession is not this character's recipe list.
  if IsTradeSkillLinked() then
    return
  end

  local filter = getActiveTradeSkillFilter();
  if filter then
    error("Recipes for " .. tradeskillName .. " were not saved because " .. filter ..
      " is active. Clear the recipe filters and reopen the profession.");
  end

  local i = 1;
  while true do
    local _, skillType = GetTradeSkillInfo(i);
    if not skillType then
      break;
    end
    if skillType == "header" then
      ExpandTradeSkillSubClass(i);
    end
    i = i + 1;
  end

  chardumps.log:Message(string.format(L.GetSkillSpell, tradeskillName));
  local res = {};
  for i = 1, GetNumTradeSkills() do
    local skillName, skillType, numAvailable, isExpanded = GetTradeSkillInfo(i);
    if (skillType and "header" ~= skillType) then
      local link = GetTradeSkillRecipeLink(i);
      local spellID = link and tonumber(strmatch(link, "\124Henchant:(%d+)"));
      if not spellID then error("Recipe link is not available for " .. tostring(skillName)) end
      table.insert(res, spellID);
    end
  end
  table.sort(res);

  local tradeLink = GetTradeSkillListLink();
  local count = #res;
  chardumps.log:Message(string.format(L.TradeSkillFound, count));

  local data = chardumps.dumper:GetDynamicData("skillspell");
  data[tradeskillName] = res;
  chardumps.dumper:SetDynamicData("skillspell", data);
  chardumps.captureStatus:Mark("skillspell", true, tradeskillName);

  if count > 0 then
    local s = L.ttchbSkillSpell .. "\n";
    -- Update text on the Tooltip
    for k,v in pairs(data) do
      s = s .. "- " .. k .. " (" .. #v .. ")\n";
    end
    local data = mainFrame.entitiesData["skillspell"];
    if data then
      chardumps.widgets:SetTooltip(data.checkbox, L.chbSkillSpell, s);
    end
    mainFrame:UpdateEntityText("skillspell", chardumps.dumper:GetSkillspellItemsCount());
  end
end

function mainFrame:OnTaximapOpened()
  if not mainFrame:IsEntityChecked("taxi") then
    return
  end

  local res = {};
  --[[

  -1 - Cosmic map

  0 - Azeroth

  1 - Kalimdor

  2 - Eastern Kingdoms

  3 - Outland

  4 - Northrend

  5 - The Maelstrom

  6 - Pandaria

  --]]
  -- The world map keeps whatever continent it last showed; point it at the
  -- player's zone so the nodes are filed under the right continent.
  if type(SetMapToCurrentZone) == "function" and not (WorldMapFrame and WorldMapFrame:IsShown()) then
    SetMapToCurrentZone();
  end
  local continent = GetCurrentMapContinent();
  if (continent < 1) or (continent > chardumps.MAX_NUM_CONTINENT) then
    return
  end

  local L = chardumps:GetLocale();
  local arrContinent = {L.Kalimdor, L.EasternKingdoms, L.Outland, L.Northrend};
  chardumps.log:Message(L.GetTaxi .. arrContinent[continent]);
  for i = 1, NumTaxiNodes() do
    -- "NONE" nodes are shown on the map but not learned by this character.
    if TaxiNodeGetType(i) ~= "NONE" then
      table.insert(res, TaxiNodeName(i));
    end
  end
  local taxiData = chardumps.dumper:GetDynamicData("taxi");
  taxiData[continent] = res;
  chardumps.dumper:SetDynamicData("taxi", taxiData);
  chardumps.captureStatus:Mark("taxi", true, tostring(continent));

  mainFrame:UpdateEntityText("taxi", chardumps.dumper:GetTaxiItemsCount());

  chardumps.log:Message(L.CountOfTaxi .. tostring(#res));
end

function mainFrame:OnAddonLoaded(addonName)
  if addonName ~= "chardumps" then
    return
  end

  local L = chardumps:GetLocale();
  chardumps.log:Message(L.AddonName .. " " .. L.Version .. " - http://wowtransfer.com");
end

function mainFrame:OnPlayerLeavingWorld()
  local options = chardumps.options;

  local entities = {};
  for name, data in pairs(self.entitiesData) do
    entities[name] = data.checkbox:GetChecked();
  end

  -- TODO: create method
  local playerOptions = chardumps:GetPlayerOptions();

  playerOptions.entities = entities;
  playerOptions.crypt = nil; -- removed option; drop the stale saved value
  playerOptions.minimize = options.minimize;
  -- TODO: may be errors on the reading
  playerOptions.dynamicData = chardumps.dumper:GetDynamicDataAll();
  playerOptions.collectionStatus = chardumps.captureStatus:Snapshot();
  playerOptions.playedTime = chardumps.dumper.playedTime;

  chardumps:SetPlayerOptions(playerOptions);
end

function mainFrame:OnVariablesLoaded()
  chardumps.dumper:StoreAccountDump(CHD_CLIENT, true);
  local playerOptions = chardumps:GetPlayerOptions();
  chardumps.dumper:SetDynamicDataAll(playerOptions.dynamicData);
  chardumps.captureStatus:Load(playerOptions.collectionStatus, playerOptions.dynamicData);
  chardumps.dumper.playedTime = playerOptions.playedTime;
  chardumps.dumper:UpdateDynamicAllFrames();

  self:ApplyOptions();
end

chardumps.mainFrame = mainFrame;
