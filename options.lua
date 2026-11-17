local chardumps = chardumps;
local options = {
  debug = false,
};

function options:getDefault()
  local entityManager = chardumps:GetEntityManager();

  
end

function options:Init()
  self:Clear();
end

function options:Save()

end

function options:Load(accountOptions, playerOptions)

end

function options:Clear()
  self:ClearForDump();
  -- other
  -- other gui
end

function options:ClearForDump()
  self.dumpOptions = {
    entities = {},
    -- entities
    -- etc.
  };
end

---
-- Add entity for the dump, safe
function options:AddEntityForDump(name)
  self.dumpOptions.entities[name] = true;
end

---
-- Add entity for the dump, safe
function options:AddOptionForDump(name, value)
  if name == "entities" then
    chardumps.log:Error("options: Wrong name `entities`");
    return;
  end
  if value == nil then
    value = true;
  end
  self.dumpOptions[name] = value;
end

---
-- @return #table
function options:GetOptionsForDump()
  return self.dumpOptions;
end

function options:IsDebug()
  return self.debug;
end

function options:SetDebug(value)
  if value then
    value = true;
  else
    value = false;
  end
  chardumps.mainFrame:SetDebug(value);
  self.debug = value;
end

chardumps.options = options;
