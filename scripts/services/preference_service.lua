local PreferenceService = {}
local Json = include("json")

local SCHEMA_VERSION = 1
local PROFILE_KEY = "default"

local function isValidMultiplier(value)
    return type(value) == "number" and value > 0
end

local function sanitizePreferences(preferences)
    local sanitized = {}
    for itemId, multiplier in pairs(preferences or {}) do
        if type(itemId) == "string" and isValidMultiplier(multiplier) then
            sanitized[itemId] = multiplier
        end
    end
    return sanitized
end

function PreferenceService.load(mod, log)
    if not mod:HasData() then
        return {}
    end

    local encoded = mod:LoadData()
    local ok, data = pcall(Json.decode, encoded)
    if not ok or type(data) ~= "table" then
        log("Preference data is malformed; keeping existing data unchanged.")
        return {}
    end

    local profile = data.profiles and data.profiles[PROFILE_KEY]
    if type(profile) ~= "table" then
        return {}
    end

    return sanitizePreferences(profile.preferences)
end

function PreferenceService.save(mod, preferences, log)
    local payload = {
        schemaVersion = SCHEMA_VERSION,
        profiles = {
            [PROFILE_KEY] = {
                preferences = sanitizePreferences(preferences),
            },
        },
        settings = {
            language = "en",
        },
    }

    local ok, encoded = pcall(Json.encode, payload)
    if not ok then
        log("Preference data could not be encoded; existing data was preserved.")
        return false
    end

    mod:SaveData(encoded)
    return true
end

return PreferenceService
