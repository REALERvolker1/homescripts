#!/bin/sh


ws_parse () {
    #echo "$1" | jq --tab -M
    local workspaces=$(i3-msg -t get_workspaces | jq -M -c '.[]' | sed 's/ //g')
    #local visible=$(echo $workspaces | jq 'map(select(.visible == true))')
    #echo "$visible"
    #local current=$(echo $visible | jq '.[] | select(.focused == true)')

    #echo "$workspaces"

    local workplaces=""

    for ws in $workspaces; do
        local name=$(echo "$ws" | jq '.name')
        local num=$(echo "$ws" | jq '.num')
        local visible=$(echo "$ws" | jq '.visible')
        local focused=$(echo "$ws" | jq '.focused')
        if [[ $visible == "true" ]]; then
            if [[ $focused == "true" ]]; then
                local class="workspace-focused"
            else
                local class="workspace-unfocused"
            fi
        else
            local class="workspace"
        fi
        workplaces="$workplaces,{\"name\":\"$name\",\"num\":\"$num\",\"class\":\"$class\"}"
    done
    echo "[$workplaces]" | sed 's/^\[,/\[/g'
}
ws_parse
#echo "$(i3-msg -t get_workspaces | sed 's/\"name\":\"/=/g' | grep -o '=[0-9]:.' | sed 's/=//g')"
i3-msg -t subscribe -m '[ "workspace" ]' | while read line; do ws_parse "$line"; done
