-- SPDX-License-Identifier: GPL-3.0-only

------------------------------------------------------------------------------
-- Promethean UI 
-- Module: Font Override
-- Source: https://github.com/JerryBrick/promethean
------------------------------------------------------------------------------

local fontOverrides = {
    {
        family = "Roboto",
        tag = "promethean\\ui\\remastered\\fonts\\roboto_bold",
        size = 14,
        weight = 800,
        offset = {
            x = 0,
            y = 3
        },
        shadowOffset = {
            x = 1,
            y = 1
        }
    },
    {
        family = "Handel Gothic",
        tag = "promethean\\ui\\remastered\\fonts\\handel_gothic_regular_12",
        size = 14,
        weight = 600,
        offset = {
            x = 2,
            y = 0
        },
        shadowOffset = {
            x = 2,
            y = 2
        }
    },
    {
        family = "Handel Gothic",
        tag = "promethean\\ui\\remastered\\fonts\\handel_gothic_regular_14",
        size = 15,
        weight = 600,
        offset = {
            x = 4,
            y = 0
        },
        shadowOffset = {
            x = 2,
            y = 2
        }
    },
    {
        family = "Handel Gothic",
        tag = "promethean\\ui\\remastered\\fonts\\handel_gothic_regular_33",
        size = 34,
        weight = 600,
        offset = {
            x = 4,
            y = 0
        },
        shadowOffset = {
            x = 4,
            y = 4
        }
    }
}

local function setupOverrides()
    for _, font in pairs(fontOverrides) do
        local fontTag = Engine.tag.getTag(font.tag, "font")
        if(fontTag) then
            Balltze.chimera.create_font_override(fontTag.handle.handle, font.family, font.size, font.weight, font.shadowOffset.x, font.shadowOffset.y, font.offset.x, font.offset.y)
            Logger:debug("Font override created for {} with font {}", font.tag, font.family)
        else
            Logger:error("Failed to override {} font!", font.tag)
        end
    end
end

return {
    setup = setupOverrides
}
