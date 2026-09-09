---Apply window rules to a list of classes
---@param params HL.WindowRuleSpec Rules to apply to class matches. Is not mutated
---@param classlist string[] {"^(class1)$", "^(class2)$"} etc
local function multicls(params, classlist)
	local mytable
	for _i, class in ipairs(classlist) do
		mytable = Tablecpy(params)
		class = "^(" .. class .. ")$"
		if mytable.match then
			mytable.match.class = class
		else
			mytable.match = { class = class }
		end
		hl.window_rule(mytable)
	end
end

multicls({ immediate = true }, {
	"ghostrunner2-win64-shipping.exe",
	"cs2",
	"steam_app_322170",
	"steam_app_1139900",
	"steam_app_2144740",
	"steam_app_264710",
	"steam_app_387290",
	"steam_app_1057090",
	"Celeste.bin.x86_64",
	"hl_linux",
	"hl2_linux",
	"haste.exe",
	"justcause3.exe",
	"geometrydash.exe",
})

-- Fullscreen and floating Codex pet decorations.
hl.window_rule({ match = { fullscreen = true }, rounding = 0 })
hl.window_rule({ match = { class = "^(Codex)$", title = "^(Codex)$", float = true }, no_blur = true, pin = true })
hl.window_rule({
	match = { class = "^(Codex)$", title = "^(Codex)$", float = true, focus = false },
	border_size = 0,
	no_shadow = true,
	decorate = false,
})

-- Application workspace placement.
multicls({ workspace = "1" }, {
	"codium-url-handler",
	"VSCodium",
	"vscodium",
	"code-oss-url-handler",
	"code-oss",
	"codium",
})
multicls({ workspace = "2" }, {
	"LibreWolf",
	"floorp",
	"one.ablaze.floorp",
})
hl.window_rule({ match = { class = "^([Bb]rave-browser)$" }, workspace = "3" })
-- hl.window_rule({ match = { class = "^(brave-browser)$" }, workspace = "3" })
-- hl.window_rule({ match = { class = "^(Brave-browser)$" }, workspace = "3" })
hl.window_rule({ match = { class = "^(org.mozilla.firefox)$" }, workspace = "4" })
hl.window_rule({ match = { class = "^(steam)$" }, workspace = "5" })
hl.window_rule({ match = { class = "^()$", title = "^(Steam)$" }, workspace = "5", float = true }) -- steam xwayland dialogs
hl.window_rule({ match = { class = "^(org.prismlauncher.PrismLauncher)$" }, workspace = "5" })
multicls({ workspace = "6" }, {
	"discord",
	"[Vv]esktop",
	"WebCord",
})
hl.window_rule({ match = { class = "^(wlroots)$" }, workspace = "12" })

multicls({ float = true }, {
	"xfce-polkit",
	"pavucontrol",
	"pavucontrol-qt",
	"blueman-manager",
	"nm-connection-editor",
	"galculator",
	"org.gnome.Calculator",
	"app.drey.EarTag", -- I forget why this is here tbh
	"net.davidotek.pupgui2", -- same for this one
	"kvantummanager",
	"xdg-desktop-portal-gnome",
	"xdg-desktop-portal-gtk",
	"xdg-desktop-portal",
	"file-roller",
	"org.gnome.FileRoller",
})
hl.window_rule({ match = { class = "^(flameshot)$" }, float = true })
hl.window_rule({ match = { title = "^(flameshot)" }, move = "(0) (0)" })
-- 20 is the current maximum rounding, replacing the old value of 30.
hl.window_rule({ match = { class = "^(re.sonny.Junction)$" }, float = true, rounding = 20 }) -- sonnyp is the GOAT but he uses gnome so like bruh

hl.window_rule({ match = { class = "^(thunar)$", title = "^(File Operation Progress)$" }, float = true })
hl.window_rule({ match = { class = "^(thunar)$", title = "^(Bulk Rename - Rename Multiple Files)$" }, float = true })
hl.window_rule({ match = { class = "^(thunar)$", initial_title = '^(Rename ")([^"]*)(")$' }, float = true })

hl.window_rule({ match = { class = "^(nemo)$", title = "^(.*)( Properties)$" }, float = true })

hl.window_rule({ match = { class = "^(python3)$", title = "^(firewall-applet)$" }, float = true })
hl.window_rule({ match = { class = "^(python3)$", title = "^(About Firewall Applet)$" }, float = true })
hl.window_rule({ match = { class = "^(python3)$", title = "^(Configure Shields Up/Down Zones)$" }, float = true })

hl.window_rule({ match = { class = "^(org.kde.okular)$", title = "^(New Text Note — Okular)$" }, float = true }) -- stupid tooltip window

hl.window_rule({ match = { class = "^(io.bassi.Amberol)$" }, float = true, size = "(monitor_w*0.2) (monitor_h*0.6)" })

hl.window_rule({ match = { class = "^(java)$", title = "^(Loading...)$" }, float = true }) -- MPLab

hl.window_rule({ match = { class = "^(firefox)$", title = "^(Picture-in-Picture)$" }, float = true, pin = true })
hl.window_rule({
	match = { class = "^(org.mozilla.firefox)$", title = "^(Picture-in-Picture)$" },
	float = true,
	pin = true,
})
hl.window_rule({ match = { class = "^()$", title = "^(Picture in picture)$" }, float = true, pin = true })

hl.window_rule({
	match = { class = "^(xwaylandvideobridge)$" },
	opacity = "0.0 override 0.0 override",
	no_anim = true,
	no_focus = true,
	no_initial_focus = true,
})

hl.window_rule({ match = { class = "^(XEyes)$" }, pin = true })

hl.window_rule({ match = { class = "^(__scratchpad__)$" }, workspace = "special:spad", float = true })
hl.window_rule({
	match = { class = "^(hdropkitty)$" },
	float = true,
	xray = false,
	dim_around = true,
	size = "(monitor_w*0.8) (monitor_h*0.8)",
	center = true,
})

hl.window_rule({ match = { class = "^(steam)$", title = "^(Friends List)$" }, float = true })
hl.window_rule({ match = { class = "^(steam)$", title = "^(Steam Settings)$" }, float = true })
hl.window_rule({ match = { class = "^(steam)$", title = "^(Add Non-Steam Game)$" }, float = true })
