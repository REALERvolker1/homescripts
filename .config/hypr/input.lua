hl.config({
	input = {
		kb_layout = "us",
		kb_options = "caps:escape",
		follow_mouse = 1,
		accel_profile = "flat",
		touchpad = {
			natural_scroll = true,
			tap_to_click = true,
			disable_while_typing = true,
		},
	},
})

local touchpad_name = "asup1205:00-093a:2003-touchpad"
local touchpad_enabled = true -- Change to false to disable by default, including on reload.

hl.device({ name = touchpad_name, enabled = touchpad_enabled, accel_profile = "adaptive" })

-- Lua replaces the legacy script's Hyprlang variable and status file.
---@return nil
local function toggle_touchpad()
	touchpad_enabled = not touchpad_enabled
	hl.device({ name = touchpad_name, enabled = touchpad_enabled })
end

return { toggle_touchpad = toggle_touchpad }
