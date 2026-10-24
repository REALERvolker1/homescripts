-- Run from the Hyprland config directory: lua tests/monitor_modes.lua
local monitor = {
	name = "DP-1",
	width = 3840,
	height = 2160,
	refresh_rate = 60,
	scale = 1.5,
	available_modes = {
		{ width = 3840, height = 2160, refresh_rate = 60 },
		{ width = 1920, height = 1080, refresh_rate = 240 },
		{ width = 3840, height = 2160, refresh_rate = 143.981 },
	},
}
local applied = {}
local callbacks = {}
local env = setmetatable({
	hl = {
		---@return table[]
		get_monitors = function()
			return { monitor }
		end,
		---@param rule {output: string, mode: string, scale: number, cm: string, bitdepth: integer}
		monitor = function(rule)
			if rule.output == monitor.name then
				table.insert(applied, rule)
			end
		end,
		---@param _rule table
		workspace_rule = function(_rule) end,
		---@param event string
		---@param callback fun()
		on = function(event, callback)
			callbacks[event] = callback
		end,
	},
}, { __index = _G })
assert(loadfile("monitors_and_workspaces.lua", "t", env))()
assert(#applied == 1, "an already-correct scale must not prevent mode selection")
assert(applied[1].mode == "3840x2160@143.981", "resolution must take priority over refresh")
assert(applied[1].scale == 1.5)
assert(applied[1].cm == "srgb" and applied[1].bitdepth == 8, "HDR must remain disabled by default")

monitor.refresh_rate = 143.98099
callbacks["monitor.layout_changed"]()
assert(#applied == 1, "matching modes must not be reapplied due to floating-point rounding")

monitor.width, monitor.height = 1920, 1080
callbacks["monitor.added"]()
assert(#applied == 2, "a different resolution must be corrected even at the same refresh")

monitor.width, monitor.height = 3840, 2160
monitor.scale = 1
callbacks["monitor.layout_changed"]()
assert(#applied == 3 and applied[3].scale == 1.5, "scaling must still be corrected")

monitor.available_modes = {}
monitor.scale = 1.5
callbacks["monitor.added"]()
assert(#applied == 4 and applied[4].mode == "highres", "missing modes must retain the existing fallback")
monitor.scale = 1
callbacks["monitor.layout_changed"]()
assert(#applied == 4, "empty modes must not cause repeated applications")

callbacks["monitor.added"]()
assert(#applied == 5 and applied[5].cm == "srgb", "hotplug must apply color settings even if mode and scale match")
assert(loadfile("monitors_and_workspaces.lua", "t", env))()
assert(#applied == 6 and applied[6].bitdepth == 8, "reload must restore 8-bit output even if mode and scale match")
callbacks["monitor.layout_changed"]()
assert(#applied == 6, "SDR fallback must not cause repeated HDR requests on layout events")

print("monitor mode checks passed")
