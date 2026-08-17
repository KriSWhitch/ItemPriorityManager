local Priority = {}

Priority.DEFAULT = 1.00
Priority.DECREASED = 0.50
Priority.INCREASED = 1.50

local function isModified(multiplier)
    return multiplier == Priority.DECREASED or multiplier == Priority.INCREASED
end

function Priority.getMultiplier(preferences, itemId)
    return preferences[tostring(itemId)] or Priority.DEFAULT
end

function Priority.getModifiedCount(preferences)
    local count = 0
    for _, multiplier in pairs(preferences) do
        if isModified(multiplier) then
            count = count + 1
        end
    end
    return count
end

function Priority.getModificationLimit(unlockedCount)
    return math.floor(unlockedCount / 5)
end

function Priority.canSet(preferences, itemId, multiplier, unlockedCount)
    if multiplier ~= Priority.DEFAULT
        and multiplier ~= Priority.DECREASED
        and multiplier ~= Priority.INCREASED then
        return false, "Invalid priority."
    end

    local itemKey = tostring(itemId)
    local current = preferences[itemKey] or Priority.DEFAULT
    if current == multiplier then
        return true
    end

    if multiplier == Priority.DEFAULT or isModified(current) then
        return true
    end

    local used = Priority.getModifiedCount(preferences)
    local limit = Priority.getModificationLimit(unlockedCount)
    if used >= limit then
        return false, "Priority limit reached. Reset another item to Default first."
    end

    return true
end

function Priority.set(preferences, itemId, multiplier, unlockedCount)
    local allowed, reason = Priority.canSet(preferences, itemId, multiplier, unlockedCount)
    if not allowed then
        return false, reason
    end

    local itemKey = tostring(itemId)
    if multiplier == Priority.DEFAULT then
        preferences[itemKey] = nil
    else
        preferences[itemKey] = multiplier
    end

    return true
end

function Priority.increase(preferences, itemId, unlockedCount)
    local current = Priority.getMultiplier(preferences, itemId)
    if current == Priority.DECREASED then
        return Priority.set(preferences, itemId, Priority.DEFAULT, unlockedCount)
    end
    return Priority.set(preferences, itemId, Priority.INCREASED, unlockedCount)
end

function Priority.decrease(preferences, itemId, unlockedCount)
    local current = Priority.getMultiplier(preferences, itemId)
    if current == Priority.INCREASED then
        return Priority.set(preferences, itemId, Priority.DEFAULT, unlockedCount)
    end
    return Priority.set(preferences, itemId, Priority.DECREASED, unlockedCount)
end

function Priority.reset(preferences, itemId)
    preferences[tostring(itemId)] = nil
end

function Priority.resetAll(preferences)
    for itemId in pairs(preferences) do
        preferences[itemId] = nil
    end
end

function Priority.isModified(multiplier)
    return isModified(multiplier)
end

return Priority
