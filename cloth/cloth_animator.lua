--- ClothAnimator - Cloth animation controller for Defold
--- Handles velocity tracking via spring physics and random wind gusts.

local ClothAnimator = {}
ClothAnimator.__index = ClothAnimator

--- Default configuration values
ClothAnimator.DEFAULTS = {
    velocity_scale = 0.02,
    velocity_max = 0.8,
    spring_stiffness = 0.03,
    spring_damping = 0.98,
    input_force = 0.03,
    gust_min_interval = 4.0,
    gust_max_interval = 8.0,
    gust_fade_in = 1.5,
    gust_hold = 2.0,
    gust_fade_out = 4.0,
    rest_gust_enabled = true,
    active_threshold = 0.15,
    rest_threshold = 0.05,
    rest_gust_fade_in = 0.35,
    rest_gust_min_intensity = 0.1,
    rest_gust_max_intensity = 1.0,
    rest_gust_vel_scale = 2.0,
    wave_loop_duration = 4.0,
    -- Fragment shader parameters
    frag_wobble_strength = 1.0,
    frag_detection_radius = 3.0,
    frag_effect_height = 0.5,
    -- Sprite size (should be set per-sprite)
    sprite_width = 256.0,
    sprite_height = 256.0,
    -- Pivot offset: (0.5, 0.5) for CENTER pivot (Defold default)
    -- (0.5, 0.0) for TOP-CENTER pivot, (0.0, 0.5) for LEFT-CENTER, etc.
    pivot_offset_x = 0.5,
    pivot_offset_y = 0.5,
    -- Orientation: 0 = vertical (hung from top, like banners/capes)
    --              1 = horizontal (hung from left, like flags)
    orientation = 0.0,
    -- Gravity params for horizontal cloth (flags)
    -- sag_multiplier: how far cloth sags as factor of width (1.3 = 130% of width)
    -- contract_multiplier: how much cloth contracts toward anchor (0.9 = 90% of width)
    sag_multiplier = 1.0,
    contract_multiplier = 1.0,
}

ClothAnimator.PRESETS = {
    banner = {
        spring_stiffness = 0.02,
        spring_damping = 0.78,
        input_force = 0.03,
    },
    flag = {
        spring_stiffness = 0.01,
        spring_damping = 0.90,
        input_force = 0.04,
        orientation = 1.0,  -- Horizontal: hung from left side
        --sag_multiplier = 1.6,
        --contract_multiplier = 0.25,
        sag_multiplier = 1.7,
        contract_multiplier = 0.20,
        rest_gust_enabled = true,
        gust_min_interval = 0.0,
        gust_max_interval = 0.0,
        gust_hold = 4.4,
        gust_fade_in = 2.9,
        gust_fade_out = 3.4,
        frag_wobble_strength = 2.1,
        frag_detection_radius = 125.0,
        frag_effect_height = 1.4,
        wave_loop_duration = 2.2,
    },
    cape = {
        spring_stiffness = 0.01,
        spring_damping = 0.79,  -- Lower damping = more cloth movement
        input_force = 0.04,     -- Higher input force = more drag response
        velocity_max = 0.8,     -- Allow more extreme displacement
        rest_gust_enabled = true,  -- Enable rest gusts for billowing
        gust_min_interval = 3.0,
        gust_max_interval = 5.0,
    },
    curtain = {
        spring_stiffness = 0.02,
        spring_damping = 0.95,
        input_force = 0.02,
        gust_min_interval = 6.0,
        gust_max_interval = 12.0,
        gust_fade_in = 2.0,
        gust_fade_out = 4.0,
    },
}

local function merge_config(base, override)
    local result = {}
    for k, v in pairs(base) do
        result[k] = v
    end
    if override then
        for k, v in pairs(override) do
            result[k] = v
        end
    end
    return result
end

function ClothAnimator.create(sprite_url, config)
    local self = setmetatable({}, ClothAnimator)

    self._sprite_url = sprite_url
    self._config = merge_config(ClothAnimator.DEFAULTS, config)

    self._disp_x = 0
    self._disp_y = 0
    self._vel_x = 0
    self._vel_y = 0
    self._last_pos = nil

    self._gust_timer = nil
    self._gusts_enabled = true
    self._was_active = false
    self._peak_vel_mag = 0

    -- Initialize shader uniforms
    go.set(sprite_url, 'cloth_velocity', vmath.vector4(0, 0, 0, 1))

    -- Initialize sprite size uniform (with pcall fallback for materials without this uniform)
    local cfg = self._config
    pcall(go.set, sprite_url, 'sprite_size', vmath.vector4(cfg.sprite_width, cfg.sprite_height, 1, 1))
    pcall(go.set, sprite_url, 'pivot_offset', vmath.vector4(cfg.pivot_offset_x, cfg.pivot_offset_y, 0, 0))

    -- Initialize cloth_params with orientation (z component)
    -- cloth_params: x=speed, y=amplitude, z=orientation, w=edge_influence
    pcall(go.set, sprite_url, 'cloth_params.z', cfg.orientation)

    -- Initialize gravity params for horizontal cloth (mesh only)
    -- cloth_gravity: x=sag_multiplier, y=contract_multiplier
    pcall(go.set, sprite_url, 'cloth_gravity', vmath.vector4(cfg.sag_multiplier, cfg.contract_multiplier, 0, 0))

    -- Initialize fragment shader parameters (with pcall fallback)
    pcall(go.set, sprite_url, 'cloth_frag_params',
        vmath.vector4(cfg.frag_wobble_strength, cfg.frag_detection_radius, cfg.frag_effect_height, 0))

    -- Start cloth_time animation loop
    go.animate(sprite_url, 'cloth_time.x', go.PLAYBACK_LOOP_FORWARD,
        1.0, go.EASING_LINEAR, cfg.wave_loop_duration)

    -- Start random gust system
    self:_start_gust_timer()

    return self
end

function ClothAnimator.create_banner(sprite_url, config)
    return ClothAnimator.create(sprite_url, merge_config(ClothAnimator.PRESETS.banner, config))
end

function ClothAnimator.create_flag(sprite_url, config)
    return ClothAnimator.create(sprite_url, merge_config(ClothAnimator.PRESETS.flag, config))
end

function ClothAnimator.create_cape(sprite_url, config)
    return ClothAnimator.create(sprite_url, merge_config(ClothAnimator.PRESETS.cape, config))
end

function ClothAnimator.create_curtain(sprite_url, config)
    return ClothAnimator.create(sprite_url, merge_config(ClothAnimator.PRESETS.curtain, config))
end

function ClothAnimator:update(dt, world_pos, world_scale)
    if not self._sprite_url then return end

    local cfg = self._config

    if self._last_pos then
        local input_x = (world_pos.x - self._last_pos.x) * cfg.velocity_scale
        local input_y = (world_pos.y - self._last_pos.y) * cfg.velocity_scale

        local input_force_x = -input_x * cfg.input_force
        local input_force_y = -input_y * cfg.input_force

        local spring_force_x = -self._disp_x * cfg.spring_stiffness
        local spring_force_y = -self._disp_y * cfg.spring_stiffness

        self._vel_x = (self._vel_x + input_force_x + spring_force_x) * cfg.spring_damping
        self._vel_y = (self._vel_y + input_force_y + spring_force_y) * cfg.spring_damping

        self._disp_x = self._disp_x + self._vel_x
        self._disp_y = self._disp_y + self._vel_y

        local disp_mag = math.sqrt(self._disp_x ^ 2 + self._disp_y ^ 2)
        if disp_mag > cfg.velocity_max then
            local scale = cfg.velocity_max / disp_mag
            self._disp_x = self._disp_x * scale
            self._disp_y = self._disp_y * scale
            disp_mag = cfg.velocity_max
        end

        local vel_mag = math.sqrt(self._vel_x ^ 2 + self._vel_y ^ 2)
        if self._was_active then
            self._peak_vel_mag = math.max(self._peak_vel_mag, vel_mag)
        end

        if cfg.rest_gust_enabled then
            if disp_mag > cfg.active_threshold then
                self._was_active = true
            elseif self._was_active and disp_mag < cfg.rest_threshold then
                self._was_active = false
                local intensity = math.max(cfg.rest_gust_min_intensity,
                    math.min(cfg.rest_gust_max_intensity, self._peak_vel_mag * cfg.rest_gust_vel_scale))
                self:_trigger_gust(intensity, cfg.rest_gust_fade_in)
                self._peak_vel_mag = 0
            end
        end

        local current_gust = go.get(self._sprite_url, 'cloth_velocity.z') or 0
        local s = world_scale or 1.0
        go.set(self._sprite_url, 'cloth_velocity',
            vmath.vector4(-self._disp_x, -self._disp_y, current_gust, s))
    end

    self._last_pos = world_pos
end

function ClothAnimator:trigger_gust(intensity, fade_in)
    self:_trigger_gust(intensity, fade_in)
end

function ClothAnimator:set_gusts_enabled(enabled)
    self._gusts_enabled = enabled
    if enabled and not self._gust_timer then
        self:_start_gust_timer()
    elseif not enabled and self._gust_timer then
        timer.cancel(self._gust_timer)
        self._gust_timer = nil
    end
end

function ClothAnimator:set_spring(stiffness, damping)
    self._config.spring_stiffness = stiffness
    self._config.spring_damping = damping
end

function ClothAnimator:set_frag_params(wobble_strength, detection_radius, effect_height)
    if not self._sprite_url then return end
    self._config.frag_wobble_strength = wobble_strength or self._config.frag_wobble_strength
    self._config.frag_detection_radius = detection_radius or self._config.frag_detection_radius
    self._config.frag_effect_height = effect_height or self._config.frag_effect_height
    pcall(go.set, self._sprite_url, 'cloth_frag_params',
        vmath.vector4(self._config.frag_wobble_strength, self._config.frag_detection_radius, self._config.frag_effect_height, 0))
end

function ClothAnimator:set_sprite_size(width, height, pivot_offset_x, pivot_offset_y)
    if not self._sprite_url then return end
    self._config.sprite_width = width or self._config.sprite_width
    self._config.sprite_height = height or self._config.sprite_height
    self._config.pivot_offset_x = pivot_offset_x or self._config.pivot_offset_x
    self._config.pivot_offset_y = pivot_offset_y or self._config.pivot_offset_y
    pcall(go.set, self._sprite_url, 'sprite_size', vmath.vector4(self._config.sprite_width, self._config.sprite_height, 1, 1))
    pcall(go.set, self._sprite_url, 'pivot_offset', vmath.vector4(self._config.pivot_offset_x, self._config.pivot_offset_y, 0, 0))
end

function ClothAnimator:set_gravity_params(sag_multiplier, contract_multiplier)
    if not self._sprite_url then return end
    self._config.sag_multiplier = sag_multiplier or self._config.sag_multiplier
    self._config.contract_multiplier = contract_multiplier or self._config.contract_multiplier
    pcall(go.set, self._sprite_url, 'cloth_gravity', vmath.vector4(self._config.sag_multiplier, self._config.contract_multiplier, 0, 0))
end

function ClothAnimator:destroy()
    if self._gust_timer then
        timer.cancel(self._gust_timer)
        self._gust_timer = nil
    end
    if self._sprite_url then
        go.cancel_animations(self._sprite_url, 'cloth_time.x')
        go.cancel_animations(self._sprite_url, 'cloth_velocity.z')
    end
    self._sprite_url = nil
end

function ClothAnimator:_start_gust_timer()
    if not self._gusts_enabled then return end
    if self._gust_timer then
        timer.cancel(self._gust_timer)
    end
    local cfg = self._config
    local interval = cfg.gust_min_interval + math.random() * (cfg.gust_max_interval - cfg.gust_min_interval)
    self._gust_timer = timer.delay(interval, false, function()
        self:_trigger_gust()
    end)
end

function ClothAnimator:_trigger_gust(intensity, fade_in)
    if not self._sprite_url then return end

    local cfg = self._config
    intensity = intensity or 1.0
    fade_in = fade_in or cfg.gust_fade_in

    local ok = pcall(go.animate, self._sprite_url, 'cloth_velocity.z', go.PLAYBACK_ONCE_FORWARD,
        intensity, go.EASING_INSINE, fade_in, 0, function()
            timer.delay(cfg.gust_hold, false, function()
                if self._sprite_url then
                    local ok2 = pcall(go.animate, self._sprite_url, 'cloth_velocity.z', go.PLAYBACK_ONCE_FORWARD,
                        0.0, go.EASING_OUTSINE, cfg.gust_fade_out, 0, function()
                            self:_start_gust_timer()
                        end)
                    if not ok2 then
                        self._sprite_url = nil
                    end
                end
            end)
        end)
    if not ok then
        self._sprite_url = nil
    end
end

return ClothAnimator
