-- SPDX-License-Identifier: GPL-3.0-only

------------------------------------------------------------------------------
-- Promethean UI 
-- Module: Cursor
-- Source: https://github.com/JerryBrick/promethean
------------------------------------------------------------------------------

local cursors = {
    stock = "ui\\shell\\bitmaps\\cursor",
    remastered = "promethean\\ui\\remastered\\bitmaps\\cursor"
}

local stockCursorDataAddress = nil

local function setCursor(cursor) 
    local targetCursorTag = Engine.tag.getTag(cursor, "bitmap")
    local stockCursorTag = Engine.tag.getTag(cursors.stock, "bitmap")
    if targetCursorTag == nil or stockCursorTag == nil then
        return
    end
    if not stockCursorDataAddress then
        stockCursorDataAddress = stockCursorTag.dataAddress
    end
    stockCursorTag.dataAddress = targetCursorTag.dataAddress
end

local function setupCursor()
    -- Set remastered cursor
    setCursor(cursors.remastered)

    -- Change cursor scale
    Balltze.event.uiWidgetBackgroundRender.subscribe(function(context)
        if context.args.widget == nil then
            local vertices = context.args.vertices
            local width = vertices.topRight.x - vertices.topLeft.x
            local height = vertices.bottomLeft.y - vertices.topLeft.y
            if width == 32 and height == 32 then
                local scale = 0.7
                vertices.topRight.x = vertices.topLeft.x + (vertices.topRight.x - vertices.topLeft.x) * scale
                vertices.bottomRight.x = vertices.bottomLeft.x + (vertices.bottomRight.x - vertices.bottomLeft.x) * scale
                vertices.bottomRight.y = vertices.topRight.y + (vertices.bottomRight.y - vertices.topRight.y) * scale
                vertices.bottomLeft.y = vertices.topLeft.y + (vertices.bottomLeft.y - vertices.topLeft.y) * scale
            end
        end
    end)
end

return {
    setCursor = setCursor,
    setup = setupCursor
}
