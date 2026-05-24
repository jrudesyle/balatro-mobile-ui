--- STEAMODDED HEADER
--- MOD_NAME: Mobile UI
--- MOD_ID: mobile-ui
--- MOD_AUTHOR: [rudesyle]
--- MOD_DESCRIPTION: Improves readability, touch usability, and visual hierarchy for mobile/Android Balatro.
--- VERSION: 1.1.0
--- PRIORITY: -100

-- ======================================================
-- Mobile UI Mod for Balatro (Android/Touch)
-- ======================================================
-- Hooks into UI system to improve:
--  - Text readability (bigger small text)
--  - Touch targets (bigger buttons, more spacing)
--  - Visual hierarchy (active blind prominence)
--  - Reduced border/outline clutter
--  - Better color contrast and saturation
--  - Improved HUD layout
--  - Optimized blind select for mobile

local MOD = SMODS.current_mod
local cfg = MOD.config

-- Helper: cross-fade between two colours
local function mix_colours(c1, c2, t)
    if not c1 or not c2 then return c1 or c2 or {1,1,1,1} end
    t = t or 0.5
    return {
        c1[1] * (1 - t) + c2[1] * t,
        c1[2] * (1 - t) + c2[2] * t,
        c1[3] * (1 - t) + c2[3] * t,
        (c1[4] or 1) * (1 - t) + (c2[4] or 1) * t
    }
end

local function is_active(feature)
    return cfg[feature] == true
end

local function desaturate(colour, amount)
    if not colour or not colour[1] then return colour end
    local gray = (colour[1] + colour[2] + colour[3]) / 3
    return {
        colour[1] * amount + gray * (1 - amount),
        colour[2] * amount + gray * (1 - amount),
        colour[3] * amount + gray * (1 - amount),
        colour[4] or 1
    }
end

local function darken(colour, amount)
    if not colour or not colour[1] then return colour end
    return {
        colour[1] * (1 - amount),
        colour[2] * (1 - amount),
        colour[3] * (1 - amount),
        colour[4] or 1
    }
end

local function copy_colour(c)
    if not c then return nil end
    return {c[1], c[2], c[3], c[4] or 1}
end

local function get_text_boost(original_scale)
    if not is_active('boost_text') then return 1 end
    if not original_scale then return 1 end
    if original_scale < 0.35 then
        return cfg.text_scale_mult
    end
    if original_scale < 0.5 then
        local t = (original_scale - 0.35) / 0.15
        return 1 + (cfg.text_scale_mult - 1) * (1 - t)
    end
    return 1
end

-- Helper: boost a node's direct text scales recursively
local function boost_text_node(node, mult)
    if not node then return end
    if node.config and node.config.scale then
        node.config.scale = node.config.scale * mult
    end
    if node.nodes then
        for _, n in ipairs(node.nodes) do boost_text_node(n, mult) end
    end
    if node.config and node.config.object and node.config.object.config then
        local oc = node.config.object.config
        if oc.scale then oc.scale = oc.scale * mult end
    end
end

-- Helper: boost padding/outline on nodes recursively
local function boost_layout_node(node, p_boost, o_mult)
    if not node then return end
    if node.config then
        if node.config.padding then node.config.padding = node.config.padding * p_boost end
        if node.config.minh then node.config.minh = node.config.minh * 1.15 end
        if node.config.minw then node.config.minw = node.config.minw * 1.1 end
        if o_mult and node.config.outline then
            node.config.outline = node.config.outline * o_mult
        end
    end
    if node.nodes then
        for _, n in ipairs(node.nodes) do boost_layout_node(n, p_boost, o_mult) end
    end
    if node.config and node.config.object and node.config.object.config then
        local oc = node.config.object.config
        if oc.scale then oc.scale = oc.scale * get_text_boost(oc.scale) end
        if oc.maxw then oc.maxw = oc.maxw * 1.1 end
    end
end

---------------------------------------------------------
-- UTILITY
---------------------------------------------------------

-- (moved above boost_text_node for proper Lua local scoping)

---------------------------------------------------------
-- ORIGINALS
---------------------------------------------------------

local _orig_DynaText_init = DynaText and DynaText.init
local _orig_UIBox_button = UIBox_button
local _orig_create_UIBox_buttons = create_UIBox_buttons
local _orig_create_UIBox_blind_choice = create_UIBox_blind_choice
local _orig_create_UIBox_HUD = create_UIBox_HUD
local _orig_create_UIBox_blind_select = create_UIBox_blind_select
local _orig_game_update = Game.update
local _orig_love_update = love.update

---------------------------------------------------------
-- 1. HOOK: DynaText:init - Boost small text
---------------------------------------------------------

if DynaText and DynaText.init then
    DynaText.init = function(self, config)
        if config and config.scale then
            local boost = get_text_boost(config.scale)
            if boost > 1 then
                config.scale = config.scale * boost
                if config.maxw then
                    config.maxw = config.maxw * 1.15
                end
            end
        end
        return _orig_DynaText_init(self, config)
    end
end

---------------------------------------------------------
-- 2. HOOK: UIBox_button - Bigger touch targets
---------------------------------------------------------

if is_active('boost_buttons') and _orig_UIBox_button then
    UIBox_button = function(args)
        args = args or {}
        if args.minw then args.minw = args.minw * cfg.button_minw_boost end
        if args.minh then args.minh = args.minh * cfg.button_minh_boost end
        if args.scale then args.scale = args.scale * cfg.button_scale_boost end
        if args.padding then args.padding = args.padding * cfg.button_padding_boost end
        return _orig_UIBox_button(args)
    end
end

---------------------------------------------------------
-- 3. HOOK: create_UIBox_buttons
---------------------------------------------------------

if is_active('boost_buttons') and _orig_create_UIBox_buttons then
    create_UIBox_buttons = function()
        local result = _orig_create_UIBox_buttons()
        local function boost(node)
            if not node then return end
            if node.config then
                if node.config.padding then node.config.padding = node.config.padding * cfg.button_padding_boost end
                if node.config.minh then node.config.minh = node.config.minh * cfg.button_minh_boost end
                if node.config.minw then node.config.minw = node.config.minw * cfg.button_minw_boost end
            end
            if node.nodes then for _, n in ipairs(node.nodes) do boost(n) end end
        end
        boost(result)
        return result
    end
end

---------------------------------------------------------
-- 4. HOOK: create_UIBox_blind_choice
---------------------------------------------------------

if is_active('improve_blind_select') and _orig_create_UIBox_blind_choice then
    create_UIBox_blind_choice = function(type, run_info)
        local result = _orig_create_UIBox_blind_choice(type, run_info)
        -- Boost all text in blind choices
        boost_text_node(result, 1.15)
        -- Boost layout (padding, spacing, min sizes)
        boost_layout_node(result, cfg.blind_padding_boost, cfg.reduce_outline)
        return result
    end
end

-- 4b. Also boost the blind select container for more vertical spacing

if is_active('improve_blind_select') and _orig_create_UIBox_blind_select then
    create_UIBox_blind_select = function()
        local result = _orig_create_UIBox_blind_select()
        if result and result.config then
            if result.config.padding then result.config.padding = result.config.padding * cfg.blind_padding_boost end
        end
        -- Boost spacing between blind cards
        boost_layout_node(result, cfg.blind_padding_boost, cfg.reduce_outline)
        return result
    end
end

---------------------------------------------------------
-- 5. (merged into 4b above)

---------------------------------------------------------
-- 6. HOOK: create_UIBox_HUD
---------------------------------------------------------

if is_active('improve_hud_layout') and _orig_create_UIBox_HUD then
    create_UIBox_HUD = function()
        local result = _orig_create_UIBox_HUD()
        boost_text_node(result, 1.15)
        boost_text_node(result, 1.15)
        boost_layout_node(result, cfg.hud_spacing_boost, cfg.reduce_outline)
        return result
    end
end

-- 6b. HOOK: create_UIBox_HUD_blind (sidebar blind info)
---------------------------------------------------------

if is_active('improve_hud_layout') then
    local _orig_HUD_blind = create_UIBox_HUD_blind
    if _orig_HUD_blind then
        create_UIBox_HUD_blind = function()
            local result = _orig_HUD_blind()
            boost_text_node(result, 1.15)
            boost_layout_node(result, cfg.hud_spacing_boost, cfg.reduce_outline)
            return result
        end
    end
end

---------------------------------------------------------
-- 7. COLOR MODIFICATIONS
---------------------------------------------------------

local _color_applied = false

local function apply_color_mods()
    if not G or not G.C then return end

    -- Darken the dynamic background colours
    if is_active('darken_background_enabled') then
        local f = cfg.darken_background
        -- G.C.BACKGROUND is set during runtime by ease_background_colour
        -- We set a lower base by patching G.C.DYN_UI which controls the
        -- sidebar and panel backgrounds
        if G.C.DYN_UI then
            if G.C.DYN_UI.MAIN then G.C.DYN_UI.MAIN = darken(G.C.DYN_UI.MAIN, (1 - f) * 0.5) end
            if G.C.DYN_UI.DARK then G.C.DYN_UI.DARK = darken(G.C.DYN_UI.DARK, (1 - f) * 0.6) end
            if G.C.DYN_UI.BOSS_MAIN then G.C.DYN_UI.BOSS_MAIN = darken(G.C.DYN_UI.BOSS_MAIN, (1 - f) * 0.5) end
            if G.C.DYN_UI.BOSS_DARK then G.C.DYN_UI.BOSS_DARK = darken(G.C.DYN_UI.BOSS_DARK, (1 - f) * 0.6) end
            if G.C.DYN_UI.BOSS_PALE then G.C.DYN_UI.BOSS_PALE = darken(G.C.DYN_UI.BOSS_PALE, (1 - f) * 0.5) end
        end
        -- Darken the static background elements
        if G.C.UI and G.C.UI.TRANSPARENT_DARK then
            G.C.UI.TRANSPARENT_DARK = {0, 0, 0, math.min(0.8, (G.C.UI.TRANSPARENT_DARK[4] or 0.5) * (2 - f))}
        end
        -- Darken the background pattern colour transitions
        if G.C.BLIND then
            for k, v in pairs(G.C.BLIND) do
                if type(v) == 'table' and v[1] and v[2] and v[3] then
                    G.C.BLIND[k] = darken(v, (1 - f) * 0.3)
                end
            end
        end
    end

    if is_active('reduce_saturation_enabled') then
        local s = cfg.reduce_saturation
        if G.C.UI then
            if G.C.UI.BACKGROUND_DARK then G.C.UI.BACKGROUND_DARK = desaturate(G.C.UI.BACKGROUND_DARK, s) end
            if G.C.UI.BACKGROUND_LIGHT then G.C.UI.BACKGROUND_LIGHT = desaturate(G.C.UI.BACKGROUND_LIGHT, s) end
            if G.C.UI.BACKGROUND_INACTIVE then G.C.UI.BACKGROUND_INACTIVE = desaturate(G.C.UI.BACKGROUND_INACTIVE, s) end
            if G.C.UI.OUTLINE_DARK then G.C.UI.OUTLINE_DARK = desaturate(G.C.UI.OUTLINE_DARK, s) end
            if G.C.UI.OUTLINE_LIGHT then G.C.UI.OUTLINE_LIGHT = desaturate(G.C.UI.OUTLINE_LIGHT, s) end
        end
        if G.C.SECONDARY_SET then
            if G.C.SECONDARY_SET.Default then G.C.SECONDARY_SET.Default = desaturate(G.C.SECONDARY_SET.Default, s) end
            if G.C.SECONDARY_SET.Enhanced then G.C.SECONDARY_SET.Enhanced = desaturate(G.C.SECONDARY_SET.Enhanced, s) end
            if G.C.SECONDARY_SET.Joker then G.C.SECONDARY_SET.Joker = desaturate(G.C.SECONDARY_SET.Joker, s) end
        end
        if G.C.GREY then G.C.GREY = desaturate(G.C.GREY, s) end
        if G.C.L_BLACK then G.C.L_BLACK = desaturate(G.C.L_BLACK, s) end
        if G.C.JOKER_GREY then G.C.JOKER_GREY = desaturate(G.C.JOKER_GREY, s) end
        -- Also mute some secondary text colours
        if G.C.FILTER then G.C.FILTER = desaturate(G.C.FILTER, math.min(s + 0.15, 1)) end
    end

    if is_active('boost_contrast') then
        -- Brighten text
        if G.C.UI and G.C.UI.TEXT_LIGHT then
            G.C.UI.TEXT_LIGHT = copy_colour(G.C.UI.TEXT_LIGHT)
            G.C.UI.TEXT_LIGHT[4] = math.min(1, (G.C.UI.TEXT_LIGHT[4] or 1) * 1.15)
        end
        -- Darken panel backgrounds further
        if G.C.DYN_UI then
            if G.C.DYN_UI.MAIN then G.C.DYN_UI.MAIN = darken(G.C.DYN_UI.MAIN, 0.06) end
            if G.C.DYN_UI.DARK then G.C.DYN_UI.DARK = darken(G.C.DYN_UI.DARK, 0.08) end
            if G.C.DYN_UI.BOSS_MAIN then G.C.DYN_UI.BOSS_MAIN = darken(G.C.DYN_UI.BOSS_MAIN, 0.06) end
            if G.C.DYN_UI.BOSS_DARK then G.C.DYN_UI.BOSS_DARK = darken(G.C.DYN_UI.BOSS_DARK, 0.08) end
        end
        -- Increase background pattern contrast
        if G.C.BACKGROUND and G.C.BACKGROUND.contrast then
            G.C.BACKGROUND.contrast = G.C.BACKGROUND.contrast * 1.15
        end
    end

    _color_applied = true
end

---------------------------------------------------------
-- 8. CONFIGURATION TAB
---------------------------------------------------------

G.FUNCS.mui_save = function(e)
    SMODS.save_mod_config(MOD)
    G.FUNCS.exit_overlay_menu(e)
end

G.FUNCS.mui_toggle = function(e)
    -- placeholder
end

MOD.config_tab = function()
    local function toggle(name, label, col)
        return create_toggle({
            label = label, ref_table = cfg, ref_value = name,
            scale = 0.85, w = 2.5, h = 0.4,
            active_colour = col or G.C.GREEN,
            callback = 'mui_toggle',
        })
    end

    local function slider(name, label, mn, mx)
        return {n=G.UIT.R, config={align = "cm", padding = 0.04}, nodes={
            {n=G.UIT.T, config={text = label, scale = 0.4, colour = G.C.UI.TEXT_LIGHT}},
            {n=G.UIT.S, config={
                ref_table = cfg, ref_value = name,
                min = mn or 0.3, max = mx or 2.0, step = 0.05,
                w = 2.5, h = 0.4, colour = G.C.ORANGE
            }},
        }}
    end

    return {
        n = G.UIT.ROOT,
        config = { align = "tm", padding = 0.3, minw = 8 },
        nodes = {
            {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes={
                {n=G.UIT.T, config={text = "📱 Mobile UI", scale = 0.5, colour = G.C.WHITE, shadow = true}},
            }},
            {n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={
                {n=G.UIT.T, config={text = "Toggles", scale = 0.4, colour = G.C.ORANGE}},
            }},
            toggle('boost_text', 'Small Text Boost'),
            toggle('boost_buttons', 'Bigger Touch Targets'),
            toggle('boost_contrast', 'Boost Contrast'),
            toggle('reduce_outlines', 'Thinner Outlines'),
            toggle('improve_blind_select', 'Blind Select Spacing'),
            toggle('improve_hud_layout', 'Left Sidebar Spacing'),
            toggle('darken_background_enabled', 'Darken Background'),
            toggle('reduce_saturation_enabled', 'Reduce Saturation'),
            {n=G.UIT.B, config={h=0.1, w=0.1}},
            {n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={
                {n=G.UIT.T, config={text = "Adjustments", scale = 0.4, colour = G.C.ORANGE}},
            }},
            slider('text_scale_mult', 'Text Size', 1.0, 1.5),
            slider('button_padding_boost', 'Button Padding', 1.0, 2.0),
            slider('blind_padding_boost', 'Blind Card Spacing', 1.0, 2.0),
            slider('hud_spacing_boost', 'HUD Spacing', 1.0, 2.0),
            slider('reduce_outline', 'Outline %', 0.2, 1.0),
            slider('darken_background', 'Background Dark', 0.5, 1.0),
            slider('reduce_saturation', 'Saturation %', 0.3, 1.0),
            {n=G.UIT.B, config={h=0.15, w=0.1}},
            {n=G.UIT.R, config={align = "cm", padding = 0.15}, nodes={
                UIBox_button({colour = G.C.GREEN, button = 'mui_save',
                    label = {"Save"}, minw = 4, scale = 0.6}),
                {n=G.UIT.B, config={w=0.15, h=0.1}},
                UIBox_button({colour = G.C.RED, button = 'exit_overlay_menu',
                    label = {"Cancel"}, minw = 4, scale = 0.6}),
            }},
        }
    }
end

---------------------------------------------------------
-- 9. LIFECYCLE - Unified love.update hook
---------------------------------------------------------

local _notified = false
local _last_cfg_hash = nil

local function cfg_hash()
    if not cfg then return 0 end
    local h = 0
    for k, v in pairs(cfg) do
        h = h + (type(v) == 'number' and v * 100 or (v == true and 1 or 0))
    end
    return h
end

function love.update(dt)
    if _orig_love_update then _orig_love_update(dt) end

    -- Apply colors once G is ready
    if not _color_applied and G and G.C then
        apply_color_mods()
    end

    -- Show notification once
    if not _notified and G and G.E_MANAGER and _color_applied then
        _notified = true
        G.E_MANAGER:add_event(Event({
            trigger = 'after', delay = 1.0,
            func = function()
                attention_text({
                    text = '📱 Mobile UI Active',
                    scale = 0.6, hold = 2.5,
                    align = 'cm', major = G.ROOM_ATTACH,
                    offset = {x = 0, y = 2},
                    colour = G.C.GREEN,
                })
                return true
            end
        }))
    end

    -- Re-apply on config change
    local ch = cfg_hash()
    if _last_cfg_hash and _last_cfg_hash ~= ch then
        _color_applied = false
        _notified = false
    end
    _last_cfg_hash = ch
end

---------------------------------------------------------
-- INIT LOG
---------------------------------------------------------

print("📱 Mobile UI mod loaded!")
print("   Text boost:", cfg.text_scale_mult)
print("   Button padding:", cfg.button_padding_boost)
