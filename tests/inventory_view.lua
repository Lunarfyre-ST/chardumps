chardumps = {}
dofile('entity_views.lua')
local lookups = 0
GetItemInfo = function(id)
  lookups = lookups + 1
  if id == 99 then return 'Cached', '|Hitem:99|h[Cached]|h' end
end
local view = chardumps.entityViews
assert(view:InventoryItemLabel({I=42, link='|Hitem:42|h[Item]|h', N=2}) == '|Hitem:42|h[Item]|h x2')
assert(lookups == 0) -- A captured link is usable even before the item cache is populated.
assert(view:InventoryItemLabel({I=99}) == '|Hitem:99|h[Cached]|h')
assert(view:InventoryItemLabel({I=123}) == 'Item #123')
print('inventory display fallback tests passed')
