local ItemPoolService = {}

function ItemPoolService.applyPreferences(itemPool, preferences, priority, log)
    local poolCount = itemPool:GetNumItemPools()
    local changedEntries = 0
    local entryCount = 0

    for poolType = 0, poolCount - 1 do
        local entries = itemPool:GetCollectiblesFromPool(poolType)
        if entries ~= nil then
            for entryIndex, entry in ipairs(entries) do
                entryCount = entryCount + 1
                if entry.initialWeight ~= nil and entry.initialWeight > 0 then
                    local multiplier = priority.getMultiplier(preferences, entry.itemID)
                    local effectiveWeight = entry.initialWeight * multiplier
                    if effectiveWeight ~= entry.weight then
                        local ok = pcall(itemPool.SetCollectibleWeight, itemPool,
                            poolType, entryIndex, effectiveWeight)
                        if ok then
                            changedEntries = changedEntries + 1
                        else
                            log("Failed to update itemID=" .. tostring(entry.itemID)
                                .. " in pool=" .. tostring(poolType))
                        end
                    end
                end
            end
        end
    end

    if entryCount == 0 then
        log("Item pools are not initialized yet; retrying.")
        return -1
    end

    log("Applied priority multipliers to " .. tostring(changedEntries) .. " pool entries.")
    return changedEntries
end

return ItemPoolService
