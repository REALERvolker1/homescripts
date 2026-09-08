local mod = "SUPER + "
local mods = mod .. "SHIFT + "
local modc = mod .. "CTRL + "

local resize_mult = 40

local home = assert(os.getenv("HOME"), "HOME is not set")
local xdg_config_home = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")

---Quote one string as one POSIX shell argument.
---@param arg string
---@return string
local function shell_quote(arg)
	assert(not arg:find("\0", 1, true), "command arguments cannot contain NUL bytes")

	return "'" .. arg:gsub("'", "'\\''") .. "'"
end

---Shell-quote each argument before constructing an exec dispatcher.
---@param argv (string|number)[]
---@return HL.Dispatcher
local function dexec(argv)
	assert(argv[1] ~= nil, "Command cannot be empty")

	---@type string[]
	local quo = {}
	for i, arg in ipairs(argv) do
		quo[i] = shell_quote(tostring(arg))
	end
	return hl.dsp.exec_cmd(table.concat(quo, " "))
end

---Add text to the beginning of a bind options struct
---@param c_opts HL.BindOptions? Bind options to shallow-copy; not mutated
---@param prefix string
---@return HL.BindOptions?
local function prepend_description(c_opts, prefix)
	if c_opts == nil then
		return nil
	end
	local opts = Tablecpy(c_opts)
	if opts.desc ~= nil then
		opts.desc = prefix .. opts.desc
	end
	if opts.description ~= nil then
		opts.description = prefix .. opts.description
	end
	return opts
end

---Bind keys with alternatives for one-handed operation
---@param lmod string modifier key combo
---@param main string The main key
---@param alt string The alternate
---@param dispatcher HL.Dispatcher|function The operation to perform
---@param opts HL.BindOptions? Any options you want to pass. Not mutated.
local function hl_bind_with_alt(lmod, main, alt, dispatcher, opts)
	hl.bind(lmod .. main, dispatcher, opts)
	hl.bind(lmod .. alt, dispatcher, prepend_description(opts, "(Alternate) "))
end

for i, imod in ipairs({ mod, mods, modc }) do
	hl_bind_with_alt(
		imod,
		"Return",
		"T",
		dexec({ "vlk-sensible-terminal", i }),
		{ description = "Open terminal variant " .. i }
	)
	hl_bind_with_alt(
		imod,
		"Backspace",
		"Z",
		dexec({ "vlk-sensible-browser", i }),
		{ description = "Open browser variant " .. i }
	)
end

hl.bind(mod .. "Backslash", dexec({ "thunar" }), { description = "Open the file manager" })
hl.bind(mods .. "Backslash", dexec({ "mousepad" }), { description = "Open the GUI text editor" })
hl.bind(modc .. "Backslash", dexec({ "codium" }), { description = "Open the IDE" })

hl.bind(mod .. "D", dexec({ "vlk-sensible-rofi" }), { description = "Open drun-style dmenu" })
hl.bind(mods .. "D", dexec({ "rofi", "-show", "run" }), { description = "Open shell command dmenu" })

hl.bind(mod .. "period", dexec({ "rofi-charamap-menu.sh" }), { description = "Open character map / emoji picker" })

hl_bind_with_alt(
	"",
	"XF86Calculator",
	mod .. "KP_Enter",
	dexec({ "gnome-calculator" }),
	{ description = "Open the calculator" }
)

hl.bind(mod .. "Equal", dexec({ "vlklock.sh" }), { description = "Session lockscreen" })

hl.bind(
	mod .. "Escape",
	dexec({ "rofi", "-show", "powermenu" }),
	{ description = "Show the session logout/power menu" }
)

hl.bind(
	"Print",
	dexec({ "vlk-sensible-screenshot", "--region" }),
	{ description = "Interactive region-selection screenshot. Opens editor." }
)
-- I got tired of having to hit shift when making fullscreen screenshots, as it messes with gameplay
hl_bind_with_alt(
	"",
	mod .. "Print",
	"SHIFT + Print",
	dexec({ "vlk-sensible-screenshot", "--active-output" }),
	{ description = "Take a full-screen screenshot of the active monitor. Opens editor." }
)
hl.bind(
	"CTRL + Print",
	dexec({ "vlk-sensible-screenshot", "--full" }),
	{ description = "Take a screenshot of ALL monitors. Opens editor." }
)

hl.bind(mod .. "Q", Dsp.window.close(), { description = "Close a window (Like clicking the X on CSDs)" })

hl.bind(
	mods .. "R",
	dexec({ xdg_config_home .. "/hypr/scripts/reload.sh" }),
	{ description = "Full reload of Hyprland and Waybar" }
)
hl.bind(mod .. "R", dexec({ "hyprctl", "reload" }), { description = "Reload Hyprland itself" })

hl.bind(mod .. "P", Dsp.window.pseudo(), { description = "Pseudo-tile a window (really here just for ricing)" })

hl.bind(mod .. "W", Dsp.group.toggle(), { description = "Convert the currently selected tile into a tab group" })
hl.bind(mod .. "E", Dsp.group.next(), { description = "Cycle between windows in a tab group" })
hl.bind(
	mod .. "S",
	Dsp.window.move({ out_of_group = true }),
	{ description = "Move the current window out of its tab group if it is in one" }
)

hl_bind_with_alt(
	"",
	"XF86Launch3",
	"Scroll_Lock",
	require("dropdown").toggle_terminal,
	{ description = "Drop-down terminal on a special workspace" }
)
hl_bind_with_alt(
	mod,
	"XF86Launch3",
	"Scroll_Lock",
	dexec({ "gfxmenu.sh" }),
	{ description = "home-made Asus Armory Crate" }
)

hl.bind("XF86AudioRaiseVolume", dexec({ "pactl", "set-sink-volume", "@DEFAULT_SINK@", "+5%" }), {
	description = "Raise the audio volume",
	repeating = true,
	locked = true,
})
hl.bind("XF86AudioLowerVolume", dexec({ "pactl", "set-sink-volume", "@DEFAULT_SINK@", "-5%" }), {
	description = "Lower the audio volume",
	repeating = true,
	locked = true,
})
hl.bind("XF86AudioMute", dexec({ "pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle" }), {
	description = "Mute the audio",
	locked = true,
})
-- I almost never use this key
hl.bind("XF86AudioMicMute", dexec({ "playerctl", "play-pause" }), {
	description = "Play or pause the most recent audio source",
	locked = true,
})
hl.bind(mod .. "XF86AudioRaiseVolume", dexec({ "playerctl", "next" }), {
	description = "Fast-forward to the next track in the most recent audio source",
	locked = true,
})
hl.bind(mod .. "XF86AudioLowerVolume", dexec({ "playerctl", "previous" }), {
	description = "Go back to the previous track in the most recent audio source",
	locked = true,
})
hl.bind(mods .. "XF86AudioRaiseVolume", dexec({ "playerctl", "position", "5+" }), {
	description = "Fast-forward 5 seconds",
	locked = true,
})
hl.bind(mods .. "XF86AudioLowerVolume", dexec({ "playerctl", "position", "5-" }), {
	description = "Rewind 5 seconds",
	locked = true,
})

hl.bind("XF86MonBrightnessUp", dexec({ "brightnessctl", "s", "+10%" }), {
	description = "Raise built-in monitor brightness",
	repeating = true,
	locked = true,
})
hl.bind("XF86MonBrightnessDown", dexec({ "brightnessctl", "s", "10%-" }), {
	description = "Lower built-in monitor brightness",
	repeating = true,
	locked = true,
})

-- TODO: I want `disabled_on_external_mouse` from sway-input(5) but Vaxry doesn't want to implement that
hl_bind_with_alt(
	"",
	"XF86TouchpadToggle",
	mod .. "F10",
	require("input").toggle_touchpad,
	{ description = "Toggle the laptop's touchpad" }
)

hl.bind(
	mod .. "space",
	Dsp.window.float({ action = "toggle" }),
	{ description = "Toggle floating for the active window" }
)

hl.bind(
	mod .. "F",
	Dsp.window.fullscreen({
		mode = "fullscreen",
		action = "toggle",
	}),
	{ description = "Toggle fullscreen for the active window" }
)

hl.bind(mod .. "comma", Dsp.window.pin({ action = "toggle" }), { description = "Toggle pinning for the active window" })

local semicolon = "code:47"

---Bind something for the arrow keys as well as all the vim keys
---@param lmod string The modifier to use
---@param left HL.Dispatcher|function
---@param right HL.Dispatcher|function
---@param up HL.Dispatcher|function
---@param down HL.Dispatcher|function
---@param opts HL.BindOptions?
local function hl_bind_lrud(lmod, left, right, up, down, opts)
	hl_bind_with_alt(lmod, "left", "H", left, prepend_description(opts, "Left: "))
	hl_bind_with_alt(lmod, "right", "L", right, prepend_description(opts, "Right: "))
	hl.bind(lmod .. semicolon, right, prepend_description(opts, "Right: "))
	hl_bind_with_alt(lmod, "up", "K", up, prepend_description(opts, "Up: "))
	hl_bind_with_alt(lmod, "down", "J", down, prepend_description(opts, "Down: "))
end

hl_bind_lrud(
	mod,
	Dsp.focus({ direction = "left" }),
	Dsp.focus({ direction = "right" }),
	Dsp.focus({ direction = "up" }),
	Dsp.focus({ direction = "down" }),
	{
		description = "Switch window focus",
		repeating = true,
	}
)
hl_bind_lrud(
	mods,
	Dsp.window.move({ direction = "left" }),
	Dsp.window.move({ direction = "right" }),
	Dsp.window.move({ direction = "up" }),
	Dsp.window.move({ direction = "down" }),
	{
		description = "Move the active window",
		repeating = true,
	}
)
hl_bind_lrud(
	modc,
	Dsp.window.resize({
		x = -resize_mult,
		y = 0,
		relative = true,
	}),
	Dsp.window.resize({
		x = resize_mult,
		y = 0,
		relative = true,
	}),
	Dsp.window.resize({
		x = 0,
		y = -resize_mult,
		relative = true,
	}),
	Dsp.window.resize({
		x = 0,
		y = resize_mult,
		relative = true,
	}),
	{
		description = "Resize the active window",
		repeating = true,
	}
)

local sswp = ""
for i = 1, 10 do
	-- There isn't a "10" key on my keyboard, so I use "0"
	sswp = tostring(i % 10)

	hl.bind(mod .. sswp, Dsp.focus({ workspace = i }), { description = "Move to workspace " .. i })
	hl.bind(
		mods .. sswp,
		Dsp.window.move({ workspace = i, follow = true }),
		{ description = "Move current window to workspace " .. i }
	)
end

hl.bind(
	mod .. "mouse_down",
	Dsp.focus({ workspace = "e-1" }),
	{ description = "Scroll down to go to the previous workspace in numerical order" }
)
hl.bind(
	mod .. "mouse_up",
	Dsp.focus({ workspace = "e+1" }),
	{ description = "Scroll up to go to the next workspace in numerical order" }
)

hl.bind(mod .. "mouse:272", Dsp.window.drag(), {
	mouse = true,
	description = "Drag a window around just by super + grabbing",
})
hl.bind(mod .. "mouse:273", Dsp.window.resize(), {
	mouse = true,
	description = "Right-click anywhere in a window with super held down to grab-resize it",
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- Both class rules and shortcuts use the same named special workspace.
hl.bind(mod .. "minus", Dsp.workspace.toggle_special("spad"), { description = "Toggle scratchpad" })
hl.bind(
	mods .. "minus",
	Dsp.window.move({ workspace = "special:spad", follow = false }),
	{ description = "Send window to scratchpad" }
)

hl.bind(
	"XF86PowerOff",
	dexec({ "notify-send", "-a", "power button test thingy", "Power Button", "The power button was pressed!" }),
	{ description = "Report power button press" }
)
hl_bind_with_alt("ALT + ", "left", "H", dexec({ "ydotool", "key", "102:1", "102:0" }), { description = "Home" })
hl_bind_with_alt("ALT + ", "right", "L", dexec({ "ydotool", "key", "107:1", "107:0" }), { description = "End" })
hl.bind(
	mods .. "Print",
	dexec({ "vlk-sensible-screenshot", "--active-output" }),
	{ description = "Screenshot active monitor" }
)
hl.bind(modc .. "Print", dexec({ "vlk-sensible-screenshot", "--full" }), { description = "Screenshot all monitors" })
