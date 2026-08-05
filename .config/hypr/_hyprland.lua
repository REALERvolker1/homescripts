-- hyprland.conf

hl.config({
    general = {
		-- Broken on my gpu? Test
        -- allow_tearing = true,
        layout = "dwindle",
		resize_on_border = true,
        extend_border_grab_area = 20,
        hover_icon_on_border = true,
        snap = {
            enabled = true,
            border_overlap = true,
            window_gap = 10,
            monitor_gap = 10,
			respect_gaps = false,
		}
    },
    misc = {
        disable_autoreload = true,
		-- 1: on, 2: fullscreen, 3: fullscreen w/ video/game content type. I usually prefer fullscreen so cursor isn't laggy randomly
        vrr = 2,
		-- builtin wallpapers
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        font_family = "Sans",
        layers_hog_keyboard_focus = true,
        mouse_move_enables_dpms = true,
		-- 0: nope. 1: take over, 2: unfullscreen
        on_focus_under_fullscreen = 2,
        -- TODO: Learn about window swallowing
        -- enable_swallow = true,
        -- swallow_regex = "",
        -- swallow_exception_regex = "",
		middle_click_paste = true,
	},
	dwindle = {
        preserve_split = true,
    },
    cursor = {
		-- soft cursors are janky with screenshot software, but hw cursors are janky with HDMI monitors plugged in. I just can't win
        -- no_hardware_cursors = 1,
        sync_gsettings_theme = true,
        inactive_timeout = 120, -- seconds
        hide_on_key_press = true,
        hide_on_touch = true,
		hide_on_tablet = false,
        warp_on_change_workspace = 1,
        warp_on_toggle_special = 1,
    },
	input_capture = {
        -- capture_modifiers = true,
	},
    render = {
		-- 1 forces it on, 2 only activates it if the window's content_type is "game"
        direct_scanout = 1,
		-- Color management pipeline, disabling breaks HDR, which IDGAF about
		-- cm_enabled = false,
		-- Set this to 1 if screenshots are transparent
        -- keep_unmodified_copy = 1,
		-- experimental, does not work on rotated screens
        -- use_shader_blur_blend = true,
    },
    opengl = {
		nvidia_anti_flicker = true,
	},
	decoration = {
        blur = {
			enabled = true,
		},
    },
    ecosystem = {
		no_donation_nag = true,
    },
    debug = {
        disable_logs = true,
		enable_stdout_logs = false,
	}
})

-- Smart gaps on regular workspaces, copied from hyprland examples
-- This bridges categories but I have it here because it's more of a layout config
hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({ match = { float = false, workspace = "w[tv1]s[false]" }, border_size = 0 })
hl.window_rule({ match = { float = false, workspace = "w[tv1]s[false]" }, rounding = 0 })
hl.window_rule({ match = { float = false, workspace = "f[1]s[false]" }, border_size = 0 })
hl.window_rule({ match = { float = false, workspace = "f[1]s[false]" }, rounding = 0 })

-- require("classes")
require("monitors_and_workspaces")
require("keybinds")
