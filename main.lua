local mod = RegisterMod("Item Priority Manager", 1)
local Priority = include("scripts/domain/priority")
local PreferenceService = include("scripts/services/preference_service")
local ItemCatalogService = include("scripts/services/item_catalog_service")
local ItemPoolService = include("scripts/services/item_pool_service")
local Menu = include("scripts/ui/menu")

local preferences = {}
local presets = {}
local catalog = {}
local unlockedCount = 0
local supportedCount = 0
local menu = nil
local applyPending = false
local applyCompleted = false

local function log(message)
    Isaac.DebugString("[Item Priority Manager] " .. message)
end

local function createMenu()
    catalog, unlockedCount = ItemCatalogService.build()
    supportedCount = ItemCatalogService.getSupportedTotalCount()
    menu = Menu.new(mod, Priority, PreferenceService, preferences, presets, catalog,
        unlockedCount, supportedCount, log)
end

local function applySavedWeights()
    local itemPool = Game():GetItemPool()
    if type(itemPool.GetCollectiblesFromPool) ~= "function"
        or type(itemPool.SetCollectibleWeight) ~= "function" then
        log("The patched REPENTOGON runtime is required. Live item-pool weights are unavailable.")
        return false
    end

    local changedEntries = ItemPoolService.applyPreferences(itemPool, preferences, Priority, log)
    return changedEntries ~= -1
end

local function onGameStarted(_, isContinued)
    preferences, presets = PreferenceService.load(mod, log)
    createMenu()

    applyPending = not isContinued
    applyCompleted = false
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, onGameStarted)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if menu == nil then
        preferences, presets = PreferenceService.load(mod, log)
        createMenu()
    end
    if menu ~= nil then
        menu:update()
    end
    if applyPending and not applyCompleted then
        if applySavedWeights() then
            applyCompleted = true
        end
    end
end)
local menuRenderCallback = ModCallbacks.MC_POST_HUD_RENDER or ModCallbacks.MC_POST_RENDER
mod:AddCallback(menuRenderCallback, function()
    if menu ~= nil then
        menu:render()
    end
end)

if ModCallbacks.MC_INPUT_ACTION then
    mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, entity, hook, action)
        if menu ~= nil and menu:getIsOpen() then
            if hook == InputHook.GET_ACTION_VALUE then
                return 0.0
            end
            return false
        end
    end)
end