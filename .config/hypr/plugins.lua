-- Apply only registered options: absent plugins must not break the base config.
-- hyprpm-reload.service runs hyprpm reload. Plugin binaries must match Hyprland.
-- Comment individual entries to leave that setting at the plugin's default.
-- These are the production plugin options; third-party APIs have no installed stubs.
---@type table<string, string|number|boolean>
local options = {
	["plugin.borders_plus_plus.enabled"] = true,
	["plugin.borders_plus_plus.add_borders"] = 1,
	["plugin.borders_plus_plus.col.border_1"] = "rgba(ffffff53)",
	["plugin.borders_plus_plus.col.border_2"] = "rgb(2222ff)",
	["plugin.hyprfocus.enabled"] = true,
	["plugin.hyprfocus.keyboard_focus_animation"] = "flash",
	["plugin.hyprfocus.mouse_focus_animation"] = "shrink",
	["plugin.hyprfocus.flash.flash_opacity"] = 0.8,
	["plugin.hyprfocus.flash.in_bezier"] = "bezIn",
	["plugin.hyprfocus.flash.in_speed"] = 0.5,
	["plugin.hyprfocus.flash.out_bezier"] = "bezOut",
	["plugin.hyprfocus.flash.out_speed"] = 3,
	["plugin.hyprfocus.shrink.shrink_percentage"] = 0.9,
	["plugin.hyprfocus.shrink.in_bezier"] = "bezIn",
	["plugin.hyprfocus.shrink.in_speed"] = 0.5,
	["plugin.hyprfocus.shrink.out_bezier"] = "bezOut",
	["plugin.hyprfocus.shrink.out_speed"] = 3,
	["plugin.csgo_vulkan_fix.res_w"] = 1920,
	["plugin.csgo_vulkan_fix.res_h"] = 1080,
	["plugin.hyprtrails.color"] = "rgba(7857ff99)",
	["plugin.hyprwinwrap.class"] = "hyprwinwrap",
}

hl.curve("bezIn", { type = "bezier", points = { { 0.5, 0.0 }, { 1.0, 0.5 } } })
hl.curve("bezOut", { type = "bezier", points = { { 0.0, 0.5 }, { 0.5, 1.0 } } })

---@return nil
local function configure_plugins()
	for key, value in pairs(options) do
		-- get_config returns nil plus an error for an unregistered option.
		if hl.get_config(key) ~= nil then
			hl.config({ [key] = value })
		end
	end
end

configure_plugins()
hl.on("config.reloaded", configure_plugins)
