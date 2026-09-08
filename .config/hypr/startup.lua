---@return nil
local function autostart()
	hl.exec_cmd("autostart.sh")
end

---@return nil
local function notify_reload()
	hl.exec_cmd('notify-send "Hyprland reloaded"')
end

hl.on("hyprland.start", autostart)
hl.on("config.reloaded", notify_reload)
