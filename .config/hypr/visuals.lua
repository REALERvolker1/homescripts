hl.config({
	general = {
		gaps_in = 2,
		gaps_out = 4,
		border_size = 2,
		["col.active_border"] = {
			colors = { "rgb(ff0000)", "rgb(ffff00)", "rgb(00ff00)", "rgb(00ffff)", "rgb(0000ff)", "rgb(ff00ff)" },
		},
		["col.inactive_border"] = "rgba(222222ff)",
	},
	decoration = {
		rounding = 5,
		active_opacity = 1.0,
		fullscreen_opacity = 1.0,
		blur = {
			enabled = true,
			size = 6,
			passes = 2,
			ignore_opacity = true,
			new_optimizations = true,
			noise = 0.05,
			contrast = 1.0,
			brightness = 1.0,
		},
		shadow = {
			enabled = true,
			range = 8,
			render_power = 2,
			sharp = false,
			color = "rgba(7857ffee)",
			color_inactive = "rgba(1a1a1acc)",
			scale = 1.0,
		},
	},
	animations = { enabled = true },
})

-- Keep this after class rules, matching production's XWayland border override.
hl.window_rule({ name = "xwayland-stuff", match = { xwayland = true }, no_shadow = true, border_size = 1 })

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.1 } } })
hl.curve("flatlinetwo", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

---Animation speeds are in deciseconds, as in the production config.
---@param leaf string
---@param speed number
---@param curve string
---@param style? string
---@return nil
local function animate(leaf, speed, curve, style)
	hl.animation({ leaf = leaf, enabled = true, speed = speed, bezier = curve, style = style })
end

animate("windows", 2, "myBezier")
animate("windowsIn", 2, "myBezier")
animate("windowsOut", 2, "default", "popin 80%")
animate("windowsMove", 2, "myBezier")
animate("border", 10, "default")
animate("borderangle", 30, "flatlinetwo")
animate("fadeIn", 2, "default")
animate("fadeOut", 3, "default")
animate("fadeLayers", 1, "default")
hl.animation({ leaf = "fadePopups", enabled = false })
animate("workspaces", 3, "myBezier", "slidefade")
animate("specialWorkspace", 2, "myBezier", "slidevert")

-- Layer-shell surfaces, independent of application window classes.
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0, xray = false })
hl.layer_rule({ match = { namespace = "waybar" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "topbar" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "notification" }, blur = true, ignore_alpha = 0 })
