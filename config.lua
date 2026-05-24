return {
    -- Text
    text_scale_mult = 1.15,  -- Multiplier for small text (< 0.5 scale)
    text_min_scale = 0.35,   -- Minimum text scale to boost
    text_max_boost = 1.15,   -- Max multiplier for text boosts
    
    -- Colors
    darken_background = 0.85,  -- Darken green background (1=original, lower=darker)
    reduce_saturation = 0.7,   -- Reduce saturation of secondary elements
    reduce_outline = 0.6,      -- Outline thickness multiplier
    contrast_boost = 1.15,     -- Boost foreground/background contrast
    
    -- Layout  
    button_padding_boost = 1.4,   -- Increase button padding
    button_minw_boost = 1.3,      -- Increase button min width
    button_minh_boost = 1.3,      -- Increase button min height
    button_scale_boost = 1.1,     -- Increase button label scale
    
    -- Spacing
    hud_spacing_boost = 1.3,      -- Increase HUD element spacing
    blind_padding_boost = 1.3,    -- Increase blind card padding
    sidebar_minw_boost = 1.2,     -- Increase sidebar min width
    
    -- Features (toggles)
    boost_text = true,
    boost_buttons = true,
    boost_contrast = true,
    reduce_outlines = true,
    improve_blind_select = true,
    improve_hud_layout = true,
    darken_background_enabled = true,
    reduce_saturation_enabled = true,
}
