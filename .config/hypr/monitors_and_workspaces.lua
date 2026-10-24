-- Monitor-specific configs

local enable_hdr = false

local asus_fx517zm = {
	internal = "eDP-1",
	usbc_intel = "DP-1",
	usbc_nvidia = "DP-2",
	hdmi_nvidia = "HDMI-A-1",
}

--[[
Monitor transform table
0 -> normal (no transforms)
1 -> 90 degrees
2 -> 180 degrees
3 -> 270 degrees
4 -> flipped
5 -> flipped + 90 degrees
6 -> flipped + 180 degrees
7 -> flipped + 270 degrees

Can also do `mirror = "eDP-1"` to dupe screen content
]]

-- Prefer screen real estate, including advertised resolutions the display downscales.
-- hl.monitor({ output = "", mode = "highres", position = "auto", scale = 1 })

---Takes monitor names suitable for their side, ordered from most-preferred to least-preferred for that position
---@param even_monitor_names string[]
---@param odd_monitor_names string[]
---@param all_monitors_nonempty_array HL.Monitor[] An array of monitors to select from. Get this in whichever manner you prefer
---@return [HL.Monitor, HL.Monitor?] _ an array of monitors corresponding to {even, odd} or just {monitor, nil} if there is only one
local function choose_monitors(even_monitor_names, odd_monitor_names, all_monitors_nonempty_array)
	assert(all_monitors_nonempty_array[1] ~= nil, "choose_monitors requires a monitor")

	local odd_mon = nil
	local even_mon = nil

	---@type table<string, HL.Monitor>
	local monitors_by_name = {}

	for _, monitor in ipairs(all_monitors_nonempty_array) do
		monitors_by_name[monitor.name] = monitor
	end

	for _, name in ipairs(even_monitor_names) do
		even_mon = monitors_by_name[name]
		if even_mon ~= nil then
			break
		end
	end

	for _, name in ipairs(odd_monitor_names) do
		odd_mon = monitors_by_name[name]
		if odd_mon ~= nil then
			break
		end
	end

	if odd_mon ~= nil and even_mon ~= nil then
		return { even_mon, odd_mon }
	else
		return {
			even_mon or odd_mon or all_monitors_nonempty_array[1],
			nil,
		}
	end
end

---See if a monitor has the resolution you want. Mainly used for determining if I want scaling
---@param monitor HL.Monitor
---@param width_px number
---@param height_px number
---@return boolean
local function monitor_has_gteq_res(monitor, width_px, height_px)
	if type(monitor.available_modes) ~= "table" then
		return false
	end
	---@diagnostic disable-next-line
	for _, mode in ipairs(monitor.available_modes) do
		if mode.width >= width_px and mode.height >= height_px then
			return true
		end
	end

	return false
end

---@class MonitorMode
---@field width integer
---@field height integer
---@field refresh_rate number

---@param monitor HL.Monitor
---@return MonitorMode?
local function highest_resolution_mode(monitor)
	local modes = monitor.available_modes
	if type(modes) ~= "table" then
		return nil
	end
	-- Hyprland's generated stub omits the available_modes entry type.
	---@cast modes MonitorMode[]
	---@type MonitorMode?
	local best
	for _, mode in ipairs(modes) do
		local pixels = mode.width * mode.height
		local best_pixels = best and best.width * best.height or 0
		if not best or pixels > best_pixels or (pixels == best_pixels and mode.refresh_rate > best.refresh_rate) then
			best = mode
		end
	end
	return best
end

---@param apply_color? boolean Apply on reload/hotplug even when mode and scale already match.
---@return nil
local function apply_monitor_scaling(apply_color)
	hl.monitor({
		output = asus_fx517zm.internal,
		mode = "1920x1080@144",
		position = "3840x0",
		scale = 1,
	})
	for _, monitor in ipairs(hl.get_monitors()) do
		if monitor.name ~= asus_fx517zm.internal then
			local wanted_scale = monitor_has_gteq_res(monitor, 3840, 2160) and 1.5 or 1
			local mode = highest_resolution_mode(monitor)

			-- HDR falls back to sRGB on unsupported displays, so don't compare the resulting preset.
			if
				apply_color
				or math.abs(monitor.scale - wanted_scale) > 0.001
				or (
					mode
					and (
						monitor.width ~= mode.width
						or monitor.height ~= mode.height
						or math.abs(monitor.refresh_rate - mode.refresh_rate) > 0.01
					)
				)
			then
				hl.monitor({
					output = monitor.name,
					mode = mode and string.format("%dx%d@%.3f", mode.width, mode.height, mode.refresh_rate)
						or "highres",
					position = "auto",
					scale = wanted_scale,
					-- Hyprland checks EDID for HDR and tests 10-bit output, falling back when unsupported.
					cm = enable_hdr and "hdr" or "srgb",
					bitdepth = enable_hdr and 10 or 8,
				})
			end
		end
	end
end

---@return nil
local function apply_workspace_monitor_settings()
	local available = hl.get_monitors()
	-- During startup or unplugging the last output, no monitor may be ready yet.
	if #available == 0 then
		return
	end
	local monitor_selection
	local monitors = choose_monitors(
		{ asus_fx517zm.usbc_intel, asus_fx517zm.hdmi_nvidia, asus_fx517zm.usbc_nvidia },
		{ asus_fx517zm.internal },
		available
	)

	-- There is only one appropriate monitor!
	if monitors[2] == nil then
		for i = 1, 8 do
			hl.workspace_rule({
				workspace = tostring(i),
				monitor = monitors[1].name,
			})
		end
	else
		for i = 1, 8 do
			-- array indexing in lua starts at 1, don't forget!
			monitor_selection = 1 + (i & 1)
			hl.workspace_rule({
				workspace = tostring(i),
				monitor = assert(monitors[monitor_selection]).name,
			})
		end
	end
end

apply_monitor_scaling(true)
apply_workspace_monitor_settings()

-- hl.on("monitor.added", apply_workspace_monitor_settings)
-- hl.on("monitor.removed", apply_workspace_monitor_settings)

hl.on("hyprland.start", function()
	apply_monitor_scaling(true)
end)
--hl.on("config.reloaded", apply_monitor_scaling) -- stupid fucking event
hl.on("monitor.added", function()
	apply_monitor_scaling(true)
end)

hl.on("monitor.layout_changed", function()
	apply_monitor_scaling()
	apply_workspace_monitor_settings()
end)
