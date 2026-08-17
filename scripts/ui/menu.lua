local Menu = {}

local ROWS_PER_PAGE = 8
local COLUMNS = 2
local ROW_HEIGHT = 20
local COLUMN_WIDTH = 265
local LEFT = 32
local TOP = 58

function Menu.new(mod, priority, preferenceService, preferences, catalog, unlockedCount, totalCount, log)
    local state = {
        open = false,
        page = 1,
        selected = 1,
        notice = "",
        noticeFrames = 0,
        previousKeys = {},
        searchActive = false,
        searchQuery = "",
        previousSearchKeys = {},
    }
    local visibleCatalog = catalog

    local function save()
        preferenceService.save(mod, preferences, log)
    end

    local function pageCount()
        return math.max(1, math.ceil(#visibleCatalog / (ROWS_PER_PAGE * COLUMNS)))
    end

    local function selectedIndex()
        return (state.page - 1) * ROWS_PER_PAGE * COLUMNS + state.selected
    end

    local function setNotice(message)
        state.notice = message
        state.noticeFrames = 120
    end

    local function changePriority(increase)
        local item = visibleCatalog[selectedIndex()]
        if item == nil then
            return
        end

        local ok, reason
        if increase then
            ok, reason = priority.increase(preferences, item.id, unlockedCount)
        else
            ok, reason = priority.decrease(preferences, item.id, unlockedCount)
        end

        if not ok then
            setNotice(reason)
            return
        end

        save()
    end

    local function moveSelection(delta)
        local index = selectedIndex() + delta
        local pageSize = ROWS_PER_PAGE * COLUMNS
        if index < 1 then
            index = #catalog
        elseif index > #visibleCatalog then
            index = 1
        end

        state.page = math.floor((index - 1) / pageSize) + 1
        state.selected = ((index - 1) % pageSize) + 1
    end

    local function changePage(delta)
        state.page = math.max(1, math.min(pageCount(), state.page + delta))
        local firstIndex = (state.page - 1) * ROWS_PER_PAGE * COLUMNS + 1
        state.selected = math.min(state.selected, ROWS_PER_PAGE * COLUMNS,
            math.max(1, #visibleCatalog - firstIndex + 1))
    end

    local function isPressed(key)
        if key == nil then
            return false
        end
        local ok, pressed = pcall(Input.IsButtonPressed, key, 0)
        return ok and pressed == true
    end

    local function isTriggered(key)
        if key == nil then
            return false
        end
        local pressed = isPressed(key)
        local previous = state.previousKeys[key]
        state.previousKeys[key] = pressed
        return pressed and not previous
    end

    local pageUpKey = Keyboard.KEY_PAGEUP or Keyboard.KEY_PRIOR
    local pageDownKey = Keyboard.KEY_PAGEDOWN or Keyboard.KEY_NEXT
    local searchKey = Keyboard.KEY_SLASH    local backspaceKey = Keyboard.KEY_BACKSPACE

    local function rebuildSearch()
        visibleCatalog = {}
        local query = string.lower(state.searchQuery)
        for _, item in ipairs(catalog) do
            if query == "" or string.find(string.lower(item.name), query, 1, true) then
                visibleCatalog[#visibleCatalog + 1] = item
            end
        end
        state.page = 1
        state.selected = 1
    end

    local function readSearchKey()
        local character = nil
        for letter = string.byte("A"), string.byte("Z") do
            local key = Keyboard["KEY_" .. string.char(letter)]
            local pressed = isPressed(key)
            local previous = state.previousSearchKeys[key] == true
            state.previousSearchKeys[key] = pressed
            if pressed and not previous and character == nil then
                character = string.lower(string.char(letter))
            end
        end
        for digit = string.byte("0"), string.byte("9") do
            local key = Keyboard["KEY_" .. string.char(digit)]
            local pressed = key ~= nil and isPressed(key)
            local previous = state.previousSearchKeys[digit] == true
            state.previousSearchKeys[digit] = pressed
            if pressed and not previous and character == nil then
                character = string.char(digit)
            end
        end
        local spacePressed = isPressed(Keyboard.KEY_SPACE)
        local spacePrevious = state.previousSearchKeys.space == true
        state.previousSearchKeys.space = spacePressed
        if spacePressed and not spacePrevious and character == nil then
            character = " "
        end
        return character
    end

    local function consumeBlockedKeys()
        local blockedKeys = {
            Keyboard.KEY_I, Keyboard.KEY_ESCAPE, Keyboard.KEY_UP, Keyboard.KEY_DOWN,
            Keyboard.KEY_LEFT, Keyboard.KEY_RIGHT, Keyboard.KEY_W, Keyboard.KEY_A,
            Keyboard.KEY_S, Keyboard.KEY_D, Keyboard.KEY_Z, Keyboard.KEY_X,
            Keyboard.KEY_R,
        }
        for _, key in ipairs(blockedKeys) do
            if key ~= nil then
                state.previousKeys[key] = isPressed(key)
            end
        end
    end

    function state:update()
        if isTriggered(Keyboard.KEY_I) then
            if not state.searchActive then
                state.open = not state.open
            end
        end

        if not state.open then
            return
        end

        if state.noticeFrames > 0 then
            state.noticeFrames = state.noticeFrames - 1
        end

        if isTriggered(searchKey) then
            state.searchActive = not state.searchActive
        end
        if state.searchActive then
            consumeBlockedKeys()
            if isTriggered(backspaceKey) then
                state.searchQuery = string.sub(state.searchQuery, 1, -2)
                rebuildSearch()
            else
                local character = readSearchKey()
                if character ~= nil then
                    state.searchQuery = state.searchQuery .. character
                    rebuildSearch()
                end
            end
            return
        end

        if isTriggered(Keyboard.KEY_ESCAPE) then
            state.open = false
        elseif isTriggered(Keyboard.KEY_UP) or isTriggered(Keyboard.KEY_W) then
            moveSelection(-1)
        elseif isTriggered(Keyboard.KEY_DOWN) or isTriggered(Keyboard.KEY_S) then
            moveSelection(1)
        elseif isTriggered(Keyboard.KEY_LEFT) or isTriggered(Keyboard.KEY_A) then
            moveSelection(-ROWS_PER_PAGE)
        elseif isTriggered(Keyboard.KEY_RIGHT) or isTriggered(Keyboard.KEY_D) then
            moveSelection(ROWS_PER_PAGE)
        elseif isTriggered(pageUpKey) then
            changePage(-1)
        elseif isTriggered(pageDownKey) then
            changePage(1)
        elseif isTriggered(Keyboard.KEY_Z) then
            changePriority(false)
        elseif isTriggered(Keyboard.KEY_X) then
            changePriority(true)
        elseif isTriggered(Keyboard.KEY_R) then
            priority.resetAll(preferences)
            save()
            setNotice("All item priorities were reset to Default.")
        end
    end

    function state:render()
        if not state.open then
            return
        end

        local height = Isaac.GetScreenHeight()
        local used = priority.getModifiedCount(preferences)
        local limit = priority.getModificationLimit(unlockedCount)
        local pages = pageCount()

        for veilRow = 0, math.floor(height / 8) do
            Isaac.RenderText(string.rep("#", 80), 0, veilRow * 8, 0.03, 0.03, 0.04, 0.78)
        end
        Isaac.RenderText(string.rep("=", 58), 24, 12, 0.16, 0.08, 0.22, 1)
        Isaac.RenderText(string.rep("=", 58), 24, height - 56, 0.16, 0.08, 0.22, 1)

        Isaac.RenderText("ITEM PRIORITY MANAGER", LEFT, 20, 0.85, 0.78, 0.65, 1)
        Isaac.RenderScaledText("Unlocked " .. tostring(unlockedCount) .. " / " .. tostring(totalCount), LEFT, 36, 0.7, 0.7, 0.65, 0.7, 0.75, 1)
        Isaac.RenderScaledText("Changes " .. tostring(used) .. " / " .. tostring(limit), LEFT + 180, 36, 0.7, 0.7, 0.65, 0.7, 0.75, 1)
        Isaac.RenderScaledText("Page " .. tostring(state.page) .. " / " .. tostring(pages), 360, 36, 0.7, 0.7, 0.65, 0.7, 0.75, 1)
        Isaac.RenderScaledText("Search / (slash)     Z -   X +     Arrows / WASD move     I / Esc close", LEFT, height - 28, 0.7, 0.7, 0.65, 0.68, 0.74, 1)
        Isaac.RenderScaledText("Search: " .. (state.searchQuery == "" and "all items" or state.searchQuery), LEFT, 48, 0.7, 0.7, 0.65, 0.7, 0.75, 1)

        for row = 1, ROWS_PER_PAGE do
            for column = 1, COLUMNS do
                local index = (state.page - 1) * ROWS_PER_PAGE * COLUMNS
                    + (row - 1) + (column - 1) * ROWS_PER_PAGE + 1
                local item = visibleCatalog[index]
                if item ~= nil then
                    local multiplier = priority.getMultiplier(preferences, item.id)
                    local marker = "  "
                    local red, green, blue = 1, 1, 1
                    if multiplier == priority.INCREASED then
                        marker = "^ "
                        red, green, blue = 0.35, 1, 0.35
                    elseif multiplier == priority.DECREASED then
                        marker = "v "
                        red, green, blue = 1, 0.35, 0.35
                    end

                    local selectedRow = state.selected == (row + (column - 1) * ROWS_PER_PAGE)
                    if selectedRow then
                        Isaac.RenderText(">", LEFT + (column - 1) * COLUMN_WIDTH - 14,
                            TOP + (row - 1) * ROW_HEIGHT, 1, 1, 0.3, 1)
                    end

                    local name = item.name
                    if string.len(name) > 22 then
                        name = string.sub(name, 1, 21) .. "..."
                    end
                    local multiplierLabel = multiplier < 0.01 and "0" or (multiplier > 9999 and "99999" or string.format("%.0f", multiplier))
                    local text = marker .. name .. "  x" .. multiplierLabel
                    Isaac.RenderText(text, LEFT + (column - 1) * COLUMN_WIDTH,
                        TOP + (row - 1) * ROW_HEIGHT, red, green, blue, 1)
                end
            end
        end

        if state.noticeFrames > 0 then
            Isaac.RenderText(state.notice, LEFT, height - 42, 1, 0.35, 0.35, 1)
        end
    end

    state.getIsOpen = function()
        return state.open
    end

    return state
end

return Menu
