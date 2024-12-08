// note: Add `gen_blocking = false` to all proc macro invocations

// pub mod upower;

// zbus-xmlgen system net.hadess.PowerProfiles /net/hadess/PowerProfiles -o powerprofiles.rs
pub mod power_profiles;

// zbus-xmlgen system org.supergfxctl.Daemon /org/supergfxctl/Gfx -o supergfxd.rs
pub mod supergfxd;

// zbus-xmlgen session com.feralinteractive.GameMode /com/feralinteractive/GameMode -o gamemode.rs
pub mod gamemode;

// zbus-xmlgen system net.hadess.SwitcherooControl /net/hadess/SwitcherooControl -o switcherooctl.rs
pub mod switcherooctl;

// zbus-xmlgen session org.freedesktop.Notifications /org/freedesktop/Notifications -o notification.rs
// Note: Remove generated code for `org.dunstproject.cmd0`
pub mod notification;
