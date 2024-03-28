-- SPDX-License-Identifier: GPL-3.0-only

------------------------------------------------------------------------------
-- Promethean UI 
-- Module: Widget Animation
-- Source: https://github.com/JerryBrick/promethean
------------------------------------------------------------------------------

---@class AnimationTransform
---@field curve BalltzeMathBezierCurve
---@field duration integer
---@field reverse boolean
---@field value integer

---@class AnimationPositionTransform
---@field x AnimationTransform
---@field y AnimationTransform

---@class ActiveAnimationTransform
---@field position AnimationPositionTransform
---@field opacity AnimationTransform

---@class ActiveAnimation
---@field widget MetaEngineWidget
---@field initialValues table
---@field transformation ActiveAnimationTransform
---@field startTimestamp BalltzeMiscTimestamp
---@field type number

local state = {
    ---@type table<ActiveAnimation>
    activeAnimations = {},
    lastFocusedWidget = nil
}

local animationTypes = {
    onFocus = 1
}

local animationCurves = {
    linear = Balltze.math.createBezierCurve("linear"),
    easeIn = Balltze.math.createBezierCurve("ease in"),
    easeOut = Balltze.math.createBezierCurve("ease out"),
    easeInOut = Balltze.math.createBezierCurve("ease in out")
}

---@class AnimationParameters
---@field pattern string The pattern to match the widget tag path
---@field template boolean If true, the animation will be applied to all widgets with the same parent tag path
---@field type number The type of animation
---@field applyToChilds boolean If true, the animation will be applied to the child widgets
---@field transformation table The transformation to apply
---@field ignore table<string> The widget tag paths to ignore

---@type table<AnimationParameters>
local animationsParameters = {
    {
        pattern = "select_list",
        template = true,
        type = animationTypes.onFocus,
        applyToChilds = true,
        transformation = {
            position = {
                x = {
                    value = -4,
                    duration = 125,
                    curve = animationCurves.easeInOut,
                    reverse = false
                }
            }
        },
        ignore = {
            "promethean\\ui\\remastered\\common_back_button"
        }
    }
}

---@param widget MetaEngineWidget
local function getDefinitionTagPath(widget)
    local widgetTag = Engine.tag.getTag(widget.definitionTagHandle.handle)
    if not widgetTag then
        Logger:error("Attempted to get tag path of a widget with no tag")
        return nil
    end
    return widgetTag.path
end

---@param widget MetaEngineWidget
local function getWidgetLastChild(widget) 
    local currentChild = widget.childWidget
    while currentChild and currentChild.nextWidget do
        currentChild = currentChild.nextWidget
    end
    return currentChild
end

---@param widget MetaEngineWidget
---@return MetaEngineWidget|nil
local function findSelectList(widget)
    local currentChild = widget.childWidget
    while currentChild ~= nil do
        local currentChildPath = getDefinitionTagPath(currentChild)
        if currentChildPath and currentChildPath:find("select_list") then
            return currentChild
        end
        currentChild = currentChild.nextWidget
    end
    return nil
end

---@param widget MetaEngineWidget
---@return AnimationParameters|nil
local function getAnimationForWidget(widget, animationType)
    local focusedWidgetTagPath = getDefinitionTagPath(widget)
    for _, animationParameters in ipairs(animationsParameters) do
        if animationType == animationParameters.type then
            if animationParameters.template then
                if animationParameters.applyToChilds then
                    local parentWidgetTagPath = getDefinitionTagPath(widget.parentWidget)
                    if parentWidgetTagPath and parentWidgetTagPath:find(animationParameters.pattern) then
                        return animationParameters
                    end
                else
                    if focusedWidgetTagPath and focusedWidgetTagPath:find(animationParameters.pattern) then
                        return animationParameters
                    end
                end
            else
                local rootWidget = Engine.userInterface.getRootWidget()
                local rootWidgetTagPath = getDefinitionTagPath(rootWidget)
                if not animationParameters.rootWidgetTag or animationParameters.rootWidgetTag == rootWidgetTagPath then
                    if animationParameters.applyToChilds then
                        local parentWidgetTagPath = getDefinitionTagPath(widget.parentWidget)
                        if animationParameters.widgetTag == parentWidgetTagPath then
                            return animationParameters
                        end
                    else
                        if focusedWidgetTagPath == animationParameters.widgetTag then
                            return animationParameters
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function getAnimationByRootWidget(rootWidgetId)
    local rootWidgetTagPath = getDefinitionTagPath(rootWidgetId)
    local animations = {}
    for _, animationParameters in ipairs(animationsParameters) do
        if(animationParameters.rootWidgetTag and animationParameters.rootWidgetTag == rootWidgetTagPath) then
            table.insert(animations, animationParameters)
        end
    end
    return animations
end

local function invertAnimationTransform(transform) 
    if(transform.position) then
        if(transform.position.x) then
            transform.position.x.value = transform.position.x.value * -1
        end

        if(transform.position.y) then
            transform.position.y.value = transform.position.y.value * -1
        end
    end

    if(transform.opacity) then
        transform.opacity.value = transform.opacity.value * -1
    end
end

---@param widget MetaEngineWidget
---@param animationType number
local function endAnimation(widget, animationType)
    local i = 1
    while i <= #state.activeAnimations do
        local anim = state.activeAnimations[i]
        if anim.widget == widget and (not animationType or anim.type == animationType) then
            local transform = anim.transformation
            if(transform.position) then
                if(transform.position.x) then
                    if(not transform.reverse) then
                        widget.position.x = anim.initialValues.position.x + transform.position.x.value
                    else
                        widget.position.x = anim.initialValues.position.x
                    end
                end

                if(transform.position.y) then
                    if(not transform.position.y.reverse) then
                        widget.position.y = anim.initialValues.position.y + transform.position.y.value
                    else 
                        widget.position.y = anim.initialValues.position.y
                    end
                end
            end

            if(transform.opacity) then
                if(not transform.opacity.reverse) then
                    widget.opacity = anim.initialValues.opacity + transform.opacity.value
                else 
                    widget.opacity = anim.initialValues.opacity
                end
            end

            table.remove(state.activeAnimations, i)
            break
        end

        i = i + 1
    end
end

function DeepCopy(orig, copies)
    copies = copies or {}
    local origType = type(orig)
    local copy
    if (origType == 'table') then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for origKey, origValue in next, orig, nil do
                copy[DeepCopy(origKey, copies)] = DeepCopy(origValue, copies)
            end
            setmetatable(copy, DeepCopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

---@param widget MetaEngineWidget
---@param animationParams AnimationParameters
---@param revert? boolean
local function playAnimation(widget, animationParams, revert)
    if animationParams.type == animationTypes.onFocus then
        endAnimation(widget, animationTypes.onFocus)
    end

    local widgetInitialValues = {
        position = {
            x = widget.position.x,
            y = widget.position.y
        },
        opacity = widget.opacity,
        backgroundBitmapIndex = widget.bitmapIndex
    }
    
    for _, ignoredWidget in ipairs(animationParams.ignore) do
        if(ignoredWidget == getDefinitionTagPath(widget)) then
            return
        end
    end
    
    local anim = DeepCopy(animationParams)
    anim.widget = widget
    anim.startTimestamp = Balltze.misc.setTimestamp()
    anim.initialValues = widgetInitialValues

    if(revert) then
        invertAnimationTransform(anim.transformation)
    end

    table.insert(state.activeAnimations, anim)
end

local function applyWidgetAnimations() 
    local i = 1
    while i <= #state.activeAnimations do
        ---@type ActiveAnimation
        local anim = state.activeAnimations[i]
        local animWidget = anim.widget
        local animTransform = anim.transformation
        local animInitialWidgetValues = anim.initialValues
        local animElapsedMilliseconds = anim.startTimestamp:getElapsedMilliseconds()
        local animAlive = false
        
        if(animTransform.position and animTransform.position.x) then
            local initialValue = animInitialWidgetValues.position.x
            local transform = animTransform.position.x

            local t = animElapsedMilliseconds / transform.duration
            if(not transform.reverse) then
                animWidget.position.x = math.floor(transform.curve:getPoint(initialValue, initialValue + transform.value, t))
            else
                animWidget.position.x = math.floor(transform.curve:getPoint(initialValue - transform.value, initialValue, t))
            end

            if(animElapsedMilliseconds < transform.duration) then
                animAlive = true
            end
        end

        if(animTransform.position and animTransform.position.y) then
            local initialValue = animInitialWidgetValues.position.y
            local transform = animTransform.position.y

            local t = animElapsedMilliseconds / transform.duration
            if(not transform.reverse) then
                animWidget.position.y = math.floor(transform.curve:getPoint(initialValue, initialValue + transform.value, t))
            else
                animWidget.position.y = math.floor(transform.curve:getPoint(initialValue - transform.value, initialValue, t))
            end

            if(animElapsedMilliseconds < transform.duration) then
                animAlive = true
            end
        end

        if(animTransform.opacity) then
            local initialValue = animInitialWidgetValues.opacity
            local transform = animTransform.opacity

            local t = animElapsedMilliseconds / transform.duration
            if(not transform.reverse) then
                animWidget.opacity = math.floor(transform.curve:getPoint(initialValue, initialValue + transform.value, t))
            else
                animWidget.opacity = math.floor(transform.curve:getPoint(initialValue - transform.value, initialValue, t))
            end

            if(animElapsedMilliseconds < transform.duration) then
                animAlive = true
            end
        end

        if(animAlive) then
            i = i + 1
        else
            endAnimation(anim.widget, anim.type)
        end
    end
end

---@param focusedWidget MetaEngineWidget
local function playFocusAnimation(focusedWidget) 
    -- Reverse last focused widget animation
    if(state.lastFocusedWidget) then
        local lastFocusedWidgetAnim = getAnimationForWidget(state.lastFocusedWidget, animationTypes.onFocus)
        if(lastFocusedWidgetAnim) then
            Logger:debug("(mouse focus event) Reversing last focused widget animation...")
            playAnimation(state.lastFocusedWidget, lastFocusedWidgetAnim, true)
        end
    end

    local anim = getAnimationForWidget(focusedWidget, animationTypes.onFocus)
    if(anim) then
        Logger:debug("(mouse focus event) Playing animation for focused widget: " .. getDefinitionTagPath(focusedWidget))
        state.lastFocusedWidget = focusedWidget
        playAnimation(focusedWidget, anim)
    end
end

---@type BalltzeFrameEventCallback
local function onFrameEvent(context) 
    if context.time == "before" then
        applyWidgetAnimations()
    end
end

---@type BalltzeUIWidgetFocusEventCallback
local function onWidgetFocusEvent(context)
    if context.time == "after" then
        playFocusAnimation(context.args.widget)
    end
end

---@type BalltzeUIWidgetCreateEventCallback
local function onWidgetCreateEvent(context) 
    if context.time == "after" and context.args.isRootWidget then
        state.activeAnimations = {}
        state.lastFocusedWidget = nil

        -- Play focus animations when a widget is opened
        local selectList = findSelectList(context.args.widget)
        if(selectList) then
            if(selectList.focusedChild) then
                playFocusAnimation(selectList.focusedChild)
            end
        end
    end
end

---@type BalltzeUIWidgetListTabEventCallback
local function onWidgetListTabEvent(context)
    if context.time == "after" then
        return
    end

    local listWidget = context.args.widgetList
    local focusedWidget = listWidget.focusedChild
    if not focusedWidget then
        return
    end
    
    -- Reverse last focused widget animation
    if(state.lastFocusedWidget) then
        local lastFocusedWidgetAnim = getAnimationForWidget(state.lastFocusedWidget, animationTypes.onFocus)
        if(lastFocusedWidgetAnim) then
            Logger:debug("(widget list tab) Reversing last focused widget animation {}", getDefinitionTagPath(state.lastFocusedWidget))
            playAnimation(state.lastFocusedWidget, lastFocusedWidgetAnim, true)
        end
    end

    local tabType = context.args.tabType
    local nextWidget
    if tabType == "tab_thru_item_list_items_prev_vertical" or tabType == "tab_thru_item_list_items_prev_horizontal" or tabType == "tab_thru_children_prev" then
        nextWidget = focusedWidget.previousWidget
        if not nextWidget then
            nextWidget = getWidgetLastChild(listWidget)
        end
    else 
        nextWidget = focusedWidget.nextWidget
        if not nextWidget then
            nextWidget = listWidget.childWidget
        end
    end

    if not nextWidget then
        return
    end

    local anim = getAnimationForWidget(nextWidget, animationTypes.onFocus)
    if anim then
        Logger:debug("(widget list tab) Playing animation for focused widget: {}", getDefinitionTagPath(focusedWidget))
        state.lastFocusedWidget = nextWidget
        playAnimation(nextWidget, anim)
    end
end

local function setUpWidgetAnimations() 
    Balltze.event.frame.subscribe(onFrameEvent)
    Balltze.event.uiWidgetCreate.subscribe(onWidgetCreateEvent)
    Balltze.event.uiWidgetListTab.subscribe(onWidgetListTabEvent)
    Balltze.event.uiWidgetFocus.subscribe(onWidgetFocusEvent)
end

return {
    setup = setUpWidgetAnimations
}
