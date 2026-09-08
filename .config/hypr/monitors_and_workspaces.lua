-- Monitor-specific configs

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

hl.monitor({
	output = asus_fx517zm.internal,
	mode = "1920x1080@144",
	position = "3840x0",
	scale = 1,
})
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Workspace configs {{{

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

apply_workspace_monitor_settings()

-- hl.on("monitor.added", apply_workspace_monitor_settings)
-- hl.on("monitor.removed", apply_workspace_monitor_settings)
hl.on("monitor.layout_changed", apply_workspace_monitor_settings)

-- }}}
