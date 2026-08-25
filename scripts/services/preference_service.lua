local PreferenceService = {}
local Json = include("json")

local SCHEMA_VERSION = 2
local PROFILE_KEY = "default"
PreferenceService.PRESET_COUNT = 9

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

local function sanitizePresets(presets)
    local sanitized = {}
    for slot = 1, PreferenceService.PRESET_COUNT do
        local preset = presets and presets[tostring(slot)]
        if type(preset) == "table" then
            sanitized[slot] = { preferences = sanitizePreferences(preset.preferences) }
        end
    end
    return sanitized
end

function PreferenceService.load(mod, log)
    if not mod:HasData() then
        return {}, {}
    end

    local encoded = mod:LoadData()
    local ok, data = pcall(Json.decode, encoded)
    if not ok or type(data) ~= "table" then
        log("Preference data is malformed; keeping existing data unchanged.")
        return {}, {}
    end

    local profile = data.profiles and data.profiles[PROFILE_KEY]
    local preferences = type(profile) == "table" and sanitizePreferences(profile.preferences) or {}
    local presets = sanitizePresets(data.presets)

    return preferences, presets
end

function PreferenceService.save(mod, preferences, presets, log)
    local encodedPresets = {}
    for slot = 1, PreferenceService.PRESET_COUNT do
        local preset = presets and presets[slot]
        if preset ~= nil then
            encodedPresets[tostring(slot)] = { preferences = sanitizePreferences(preset.preferences) }
        end
    end

    local payload = {
        schemaVersion = SCHEMA_VERSION,
        profiles = {
            [PROFILE_KEY] = {
                preferences = sanitizePreferences(preferences),
            },
        },
        presets = encodedPresets,
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
