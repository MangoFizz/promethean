-- SPDX-License-Identifier: GPL-3.0-only

---@type Logger
Logger = {}

local fontOverride = require "fontOverride"
local cursor = require "cursor"
local widgetAnimation = require "widgetAnimation"

---@type BalltzeMapLoadEventCallback
local function onMapLoad(context) 
    if context.time == "before" then
        if context.args.name == "levels\\ui\\ui" then
            Balltze.features.setMenuAspectRatio(16, 9)
            Logger:debug("Menu aspect ratio set to 16:9")
        else
            Balltze.features.resetMenuAspectRatio()
            Logger:debug("Menu aspect ratio reset to default")
        end
    end
end

function PluginMetadata()
    return {
        name = "Promethean",
        author = "MangoFizz",
        version = "1.0.0",
        targetApi = "1.1.0",
        reloadable = false
    }
end

function PluginInit() 
    -- Set up logger
    Logger = Balltze.logger.createLogger("Promethean")
    Logger:muteIngame(true)

    -- Set up events listeners
    Balltze.event.mapLoad.subscribe(onMapLoad)

    return true
end

function PluginLoad() 
    fontOverride.setup()
    cursor.setup()
    widgetAnimation.setup()
end
