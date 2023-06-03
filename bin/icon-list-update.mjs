#!/usr/bin/env node
import {writeFile} from "node:fs/promises"
import {env} from "node:process"
/*
let reference = [
    {
        "family": "fam",
        "icons": [
            {
                "name": "icon_name",
                "icon": "%"
            }
        ]
    }
]
*/
// https://raw.githubusercontent.com/muan/unicode-emoji-json/main/data-by-group.json

const blacklist = ["mdi", "material"]
await update(`${env.XDG_CACHE_HOME}/nerd-font-icons.json`, `${env.XDG_CACHE_HOME}/nerd-font-icons.txt`)

async function update(icon_file, all_icon_file) {
    const get_git_url = file_name => `https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/bin/scripts/lib/i_${file_name}.sh`

    const request_all = await fetch(get_git_url("all"))
    if (!request_all.ok) { console.error("Could not get the icon list!") }
    const response_all = await request_all.text()

    const list_all = response_all.substring(
            (response_all.indexOf('i_{') + 3),
            response_all.indexOf('}.sh')
        ).split(",") // URL formatting

    const files = []
    let all_icons = []
    let update_file = true

    for (let icon_set of list_all) {
        if (blacklist.includes(icon_set)) continue

        let family = {
            family: icon_set,
            icons: []
        }

        try {
            const file_raw = await (await fetch(get_git_url(icon_set))).text()

            file_raw.split("\n")
                .filter(line => line.trim().startsWith("i="))
                .map(line => line.substring(
                        line.indexOf("=") + 1,
                        line.lastIndexOf("=")
                    )
                    .replace(/'/g, "")
                    .replace(/i_/, "")
                    .split(" ")
                )
                .forEach(icon => {
                    all_icons.push(`${icon[0]}=${icon[1]}`)
                    family.icons.push({
                        "name": icon[1],
                        "icon": icon[0]
                    })
                })

            files.push(family)

            console.log(`Successfully synced ${icon_set}`)
        }
        catch(e) {
            update_file = false
            console.log(`ERROR: Could not sync iconset ${icon_set}`)
        }
    } // end loop

    if (update_file) {
        await writeFile(icon_file, JSON.stringify(files))
        await writeFile(all_icon_file, all_icons.join("\n"))
    } else {
        console.log("There were errors saving your config. Please try again at another time.")
    }
}
