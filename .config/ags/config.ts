import { Variable } from "resource:///com/github/Aylur/ags/variable.js"
import App from "resource:///com/github/Aylur/ags/app.js"
import { Widget } from "resource:///com/github/Aylur/ags/widget.js"
import Audio, {
    Stream,
} from "resource:///com/github/Aylur/ags/service/audio.js"
import Battery from "resource:///com/github/Aylur/ags/service/battery.js"
import {
    interval,
    exec,
    execAsync,
} from "resource:///com/github/Aylur/ags/utils.js"
import Hyprland from "resource:///com/github/Aylur/ags/service/hyprland.js"
import AgsEventBox from "types/widgets/eventbox"

// exec('tsc -p "${XDG_CONFIG_HOME:-$HOME/.config}/ags"')

const time = new Variable("", {
    poll: [5000, ["date", "+%a %-m/%-d @ %-I:%M %P"]],
})

const volume_thing = Widget.Button({
    on_clicked: () => {
        if (!Audio.speaker) return
        Audio.speaker.stream.is_muted = !Audio.speaker.stream.is_muted
        // Audio.speaker.
    },
    child: Widget.CenterBox({
        children: [
            Widget.Icon({
                connections: [
                    [
                        Audio,
                        (self) => {
                            if (!Audio.speaker) return
                            if (Audio.speaker.stream.is_muted) {
                                self.icon = "audio-volume-muted-symbolic"
                            } else {
                                const vol = Audio.speaker.volume * 100
                                // @ts-ignore
                                const icon = [
                                    [101, "overamplified"],
                                    [67, "high"],
                                    [34, "medium"],
                                    [0, "low"],
                                    // @ts-ignore
                                ].find(([threshold]) => threshold <= vol)[1]
                                self.icon = `audio-volume-${icon}-symbolic`
                            }
                        },
                        "speaker-changed",
                    ],
                ],
            }),
            Widget.Label({
                label: "?",
                connections: [
                    [
                        Audio,
                        (self) => {
                            if (!Audio.speaker) return
                            const vol = Audio.speaker.volume * 100
                            if (Audio.speaker.stream.is_muted) {
                                self.label = ""
                                self.class_name = "volume_label_empty"
                                self.parent.tooltip_text = `Volume: ${vol.toFixed()}% (Muted)`
                            } else {
                                self.label = `${vol.toFixed()}%`
                                self.class_name = "volume_label_set"
                                self.parent.tooltip_text = `Volume: ${vol.toFixed()}%`
                            }
                        },
                        "speaker-changed",
                    ],
                ],
            }),
        ],
    }),
})

function update_workspaces(btn: AgsEventBox, id: number) {
    let is_active = Hyprland.active.workspace.id === id
    btn.toggleClassName("workspace_button_active", is_active)
    // @ts-ignore
    if (Hyprland.getWorkspace(id)?.windows < 0 && !is_active) {
        btn.hide
    } else {
        btn.show
    }
}

function switch_workspace(id: number) {
    execAsync(`hyprctl dispatch workspace ${id}`)
}

function workspace_button(id: number) {
    return Widget.EventBox({
        class_name: "workspace_button",
        on_primary_click_release: () =>
            Hyprland.sendMessage(`dispatch workspace ${id}`),
        child: Widget.Label({
            label: `${id}`,
        }),
        connections: [
            [
                Hyprland.active.workspace,
                (btn) =>
                    btn.toggleClassName(
                        "workspace_button_active",
                        Hyprland.active.workspace.id === id
                    ),
            ],
        ],
        // update_workspaces(btn, id)
    })
}

const workspace_thing = Widget.Box({
    class_name: "Workspaces",
    children: Array.from({ length: 10 }, (_, i) => i + 1).map((i) =>
        workspace_button(i)
    ),
    // connections: [
    //     [
    //         Hyprland,
    //         (box) => {
    //             box.children.forEach((btn, idx) => {
    //                 const before = Hyprland.getWorkspace(idx)
    //                 const current = Hyprland.getWorkspace(idx + 1)
    //                 const after = Hyprland.getWorkspace(idx + 2)
    //             })
    //         },
    //         "notify::workspaces",
    //     ],
    // ],
})

const Bar = (monitor: number = 0) =>
    Widget.Window({
        monitor,
        name: `bar${monitor}`,
        anchor: ["top", "left", "right"],
        exclusivity: "exclusive",
        child: Widget.CenterBox({
            start_widget: workspace_thing,
            // center_widget:
            end_widget: Widget.Box({
                children: [
                    volume_thing,
                    Widget.Label({
                        hpack: "center",
                        binds: [["label", time]],
                    }),
                ],
            }),
        }),
    })

export default {
    windows: [Bar(0)],
    style: `${App.configDir}/style.css`,
}
