#!/usr/bin/python3
import os

END_ICON = ""
END_ICON_RIGHT = ""
SHORT_MAX_LEN = 4

# ansi color class
class Color:
    reset = "\033[0m"
    def __init__(self, color: int, light = True) -> None:
        self.color = color
        if light:
            self.textcolor = 255
        else:
            self.textcolor = 232

        self.tx = f"\033[1;38;5;{self.textcolor}m"
        self.fg = f"\033[0;38;5;{self.color}m"

    def bg(self, reset = False, texttoo = False):
        textcol = ""
        if texttoo: # include text in one single ansi escape string
            textcol = f";38;5;{self.textcolor}"
        if reset:
            return f"\033[0;48;5;{self.color}{textcol}m"
        else:
            return f"\033[48;5;{self.color}{textcol}m"

    # def fg(self, reset = False):
    #     if reset:
    #         return f"\033[0;38;5;{self.color}m"
    #     else:
    #         return f"\033[38;5;{self.color}m"

class Segment:
    shortfmt = ""
    longfmt = ""
    def __init__(self, color: Color, short_text: str, long_text: str, conditional = "", conditional_state = True) -> None:
        self.color = color

        if short_text != "":
            self.shortfmt = f"{color.bg(reset = True, texttoo = True)} {short_text} {color.reset}"
            if conditional != "":
                if conditional_state:
                    # conditional is true
                    self.shortfmt = f"%({conditional}.{self.shortfmt}.)"
                else:
                    self.shortfmt = f"%({conditional}..{self.shortfmt})"

        if long_text != "":
            self.longfmt = f"{color.bg()}{END_ICON}{color.tx} {long_text} {color.fg}"
            if conditional != "":
                if conditional_state:
                    self.longfmt = f"%({conditional}.{self.longfmt}.)"
                else:
                    self.longfmt = f"%({conditional}..{self.longfmt})"

host = os.environ.get('HOSTNAME')
if host == None:
    print("Error, hostname is undefined!")
    exit(2)

host = f"%{host}%"
host = host.replace('%', '%%')

pwd_text = "%\\$((COLUMNS / 2))<..<%~"
pwd_text_short = "%\\$((COLUMNS / 4))<..<%~"

segments = {
    "log": Segment(Color(55, light=True), "", "󰌆"),
    "hos": Segment(Color(18, light=True), "󰟀", f"󰟀 {host}"),
    "dbx": Segment(Color(95, light=True), f"${{${{CONTAINER_ID::{SHORT_MAX_LEN}}}//%/%%}}", "󰆍 ${CONTAINER_ID//%/%%}"),
    "con": Segment(Color(40), f"\\${{\\${{CONDA_DEFAULT_ENV::{SHORT_MAX_LEN}}}//%/%%}}", "󱔎 \\${CONDA_DEFAULT_ENV//%/%%}"),
    "vev": Segment(Color(220), f"\\${{\\${{\\${{VIRTUAL_ENV:t}}::{SHORT_MAX_LEN}}}//%/%%}}", "󰌠 \\${\\${VIRTUAL_ENV:t}//%/%%}"),
    "job": Segment(Color(172), "", "󱜯 %j", conditional="1j"),
    "err": Segment(Color(52, light=True), "%?", "󰅗 %?", conditional="0?", conditional_state=False),
}

for key in segments.keys():
    val = segments.get(key)
    if val == None:
        print("Null value: ", val)
        continue
    print(f"\033[0m{key} => {val.longfmt}\033[0m")
