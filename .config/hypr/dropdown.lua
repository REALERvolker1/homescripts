local terminal_class = "hdropkitty"
local hidden_workspace = "special:hdrop"
local size_fraction = 0.8

---@return nil
local function toggle_terminal()
	local workspace = hl.get_active_workspace()
	local monitor = hl.get_active_monitor()
	if workspace == nil or monitor == nil then
		return
	end

	local terminal = nil
	for _, window in ipairs(hl.get_windows()) do
		if window.mapped and window.class == terminal_class then
			terminal = window
			break
		end
	end

	if terminal == nil then
		hl.exec_cmd("vlk-sensible-terminal 1 --class=hdropkitty")
		return
	end

	if terminal.workspace ~= nil and terminal.workspace.id == workspace.id then
		hl.dispatch(Dsp.window.move({ window = terminal, workspace = hidden_workspace, follow = false }))
		return
	end

	hl.dispatch(Dsp.window.move({ window = terminal, workspace = workspace, follow = false }))
	-- Avoid toggling an already-floating window on the installed 0.56 build.
	if not terminal.floating then
		hl.dispatch(Dsp.window.float({ window = terminal }))
	end
	-- Account for output scale and quarter-turn rotation when changing monitors.
	local width, height = monitor.width, monitor.height
	if monitor.transform % 2 == 1 then
		width, height = height, width
	end
	hl.dispatch(Dsp.window.resize({
		window = terminal,
		x = math.floor(width / monitor.scale * size_fraction),
		y = math.floor(height / monitor.scale * size_fraction),
		relative = false,
	}))
	hl.dispatch(Dsp.window.center({ window = terminal }))
	hl.dispatch(Dsp.focus({ window = terminal }))
end

return { toggle_terminal = toggle_terminal }
