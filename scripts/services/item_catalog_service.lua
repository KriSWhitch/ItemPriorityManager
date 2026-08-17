local ItemCatalogService = {}

local function isSupported(item)
    return item ~= nil
        and item:IsCollectible()
        and not item:IsNull()
        and not item.Hidden
end

local function getItemKind(item)
    if item.Type == ItemType.ITEM_ACTIVE then
        return "active"
    end
    return "passive"
end

local function humanizeName(name, itemId)
    if type(name) ~= "string" or name == "" then
        return "Item " .. tostring(itemId)
    end

    name = name:gsub("^#", "")
    name = name:gsub("^[Cc][Oo][Ll][Ll][Ee][Cc][Tt][Ii][Bb][Ll][Ee]_", "")
    name = name:gsub("_", " ")
    name = name:gsub("([a-z])([A-Z])", "%1 %2")
    name = name:gsub("%s+", " ")
    name = name:gsub("%s+[Nn][Aa][Mm][Ee]%s*$", "")

    return name:gsub("(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. string.lower(rest)
    end)
end

function ItemCatalogService.build()
    local itemConfig = Isaac.GetItemConfig()
    local catalog = {}
    local unlockedCount = 0

    for itemId = 1, CollectibleType.NUM_COLLECTIBLES - 1 do
        local item = itemConfig:GetCollectible(itemId)
        if isSupported(item) then
            local unlocked = item:IsAvailable()
            if unlocked then
                unlockedCount = unlockedCount + 1
                catalog[#catalog + 1] = {
                    id = itemId,
                    name = humanizeName(item.Name, itemId),
                    kind = getItemKind(item),
                    gfxFileName = item.GfxFileName,
                    unlocked = true,
                }
            end
        end
    end

    table.sort(catalog, function(left, right)
        local leftName = string.lower(left.name)
        local rightName = string.lower(right.name)
        if leftName == rightName then
            return left.id < right.id
        end
        return leftName < rightName
    end)

    return catalog, unlockedCount
end

function ItemCatalogService.getSupportedTotalCount()
    local itemConfig = Isaac.GetItemConfig()
    local count = 0

    for itemId = 1, CollectibleType.NUM_COLLECTIBLES - 1 do
        if isSupported(itemConfig:GetCollectible(itemId)) then
            count = count + 1
        end
    end

    return count
end

return ItemCatalogService
