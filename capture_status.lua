local chardumps = chardumps;
local status = {records = {}, session = {}};

local function copy(value)
  if type(value) ~= "table" then return value end
  local result = {};
  for key, item in pairs(value) do result[key] = copy(item) end
  return result;
end

function status:Load(records, legacyData)
  self.records = copy(records or {});
  self.session = {};
  -- Existing caches cannot prove when or how completely they were collected.
  for _, name in ipairs({"bank", "quest", "skillspell", "taxi"}) do
    if not self.records[name] and legacyData and legacyData[name] ~= nil then
      self.records[name] = {state = "unknown"};
    end
  end
end

function status:Mark(name, succeeded, detail, reason)
  local record = self.records[name] or {};
  record.state = succeeded and "collected" or "failed";
  record.at = time();
  record.reason = reason;
  if succeeded then record.last_success_at = record.at end
  if succeeded and detail then
    record.details = record.details or {};
    record.details[detail] = record.at;
  end
  self.records[name] = record;
  self.session[name] = true;
end

function status:Get(name)
  local record = self.records[name];
  if not record then return "not collected", nil end
  if record.state == "collected" and not self.session[name] then
    return "previously collected", record;
  end
  return record.state or "unknown", record;
end

function status:Snapshot()
  return copy(self.records);
end

chardumps.captureStatus = status;
