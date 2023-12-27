#!/usr/bin/python3
# psa, rewrittin in python by vlk to workaround bugs in procps in non-Fedora distros
# pyright: strict

# from typing import Any
from os.path import isdir
import psutil
from re import compile as regexcompile
from typing import Dict, Tuple
import os
# https://stackoverflow.com/questions/62146307/what-is-the-most-efficient-way-to-push-and-pop-a-list-in-python#62146408
from collections import deque
# https://stackoverflow.com/questions/11351032/named-tuple-and-default-values-for-optional-keyword-arguments#18348004
# from dataclasses import dataclass
from subprocess import check_output

is_full_color: bool = False
if os.environ.get("COLORTERM") == "truecolor":
    is_full_color = True
else:
    color_cmd = check_output(["tput", "colors"])
    if (int(color_cmd.decode("utf-8").strip()) >= 256):
        is_full_color = True

FULLCOLOR = is_full_color
# @dataclass(order=False, frozen=False, eq=False)
class Color:
    color_int: int
    color_str_part: str
    def __init__(self, desired_256color: int, desired_8color: int):
        if (desired_8color < 0 | desired_8color > 7):
            raise ValueError("Please use a color integer between 0 and 7 as your desired 8-color fallback!")
        if (desired_8color < 0 | desired_8color > 255):
            raise ValueError("Please use a color integer between 0 and 255 as the desired 256-color!")

        if FULLCOLOR:
            self.color_str_part = f"8;5;{desired_256color}"
            self.color_int = desired_256color
        else:
            self.color_str_part = str(desired_8color)
            self.color_int = desired_8color

    def bgfmt(self, input: str):
        return f"\033[4{self.color_str_part}m{input}\033[0m"

    def fgfmt(self, input: str, bold: bool = False):
        boldfmt: str = ''
        if bold:
            boldfmt = ";1"
        return f"\033[0{boldfmt};3{self.color_str_part}m{input}\033[0m"

__nearest_color_remove_lscolor_prefix = regexcompile("[^=]+$")
__nearest_color_regex_256col = regexcompile("38;5;[0-9]+")
__nearest_color_regex_8col = regexcompile("3[0-7]")
def get_nearest_color(maybe_ls_color: str):
    ansi_color_match = __nearest_color_remove_lscolor_prefix.search(maybe_ls_color)
    if ansi_color_match == None:
        ansi_color = maybe_ls_color
    else:
        ansi_color = ansi_color_match.group()

    matched_256 = __nearest_color_regex_256col.search(ansi_color)
    if matched_256 != None:
        return_color = matched_256.group()[-3:].removeprefix(";")
        is_256col = True
    else:
        is_256col = False
        matched_8 = __nearest_color_regex_8col.search(ansi_color)
        if matched_8 != None:
            return_color = matched_8.group()[-1:]
        else:
            return_color = "0"

    return (int(return_color), is_256col)

class ColorConfig:
    def __init__(self):
        # get ls color stuff
        dir_color: int = 94
        dir_color_fb: int = 4
        lnk_color: int = 96
        lnk_color_fb: int = 6
        exe_color: int = 92
        exe_color_fb: int = 2

        ls_colors = os.environ.get("LS_COLORS")
        if ls_colors != None:
            # https://stackoverflow.com/questions/3640359/regular-expressions-search-in-list
            regex = regexcompile("^(di|ln|ex)=.+")
            color_list = list(filter(regex.match, ls_colors.split(":")))
            tmp_color: int = 0
            for i in color_list:
                i_nearest_color = get_nearest_color(i)
                tmp_color = i_nearest_color[0]
                if i.startswith("di"):
                    dir_color = tmp_color
                    if i_nearest_color[1]:
                        dir_color_fb = i_nearest_color[0]
                elif i.startswith("ln"):
                    lnk_color = tmp_color
                    if i_nearest_color[1]:
                        lnk_color_fb = i_nearest_color[0]
                elif i.startswith("ex"):
                    exe_color = tmp_color
                    if i_nearest_color[1]:
                        exe_color_fb = i_nearest_color[0]

        # FsColors
        self.fs_dir = Color(dir_color, dir_color_fb)
        self.fs_lnk = Color(lnk_color, lnk_color_fb)
        self.fs_exe = Color(exe_color, exe_color_fb)

        # fmt color preferences
        self.ps_pid = Color(202, 3)
        self.ps_name = Color(27, 4)
        self.ps_user = Color(93, 5)
        self.ps_user_root = Color(124, 1)
        self.ps_nice_lo = Color(118, 2)
        self.ps_nice_hi = Color(196, 1)
        self.ps_args = Color(72, 6)

        # self.fmtcache: Dict[str, str] = {"": ""}


    def color_cmd_arg(self, arg: str, known_prefix: str = "", known_suffix: str = ""):
        unfmt_full_arg = known_prefix + arg + known_suffix
        if unfmt_full_arg in self.fmtcache:
            fmt_full_arg = self.fmtcache[unfmt_full_arg]
        else:
            fmt_arg_pre = ""
            fmt_arg_suf = ""
            if (known_prefix != ""):
                fmt_arg_pre = self.fmt_arg_if_not_exists(known_prefix)
            if (known_suffix == ""):
                fmt_arg_suf = self.fmt_arg_if_not_exists(known_suffix)

            fmt_arg = self.fmt_filepath(arg)

            fmt_full_arg = fmt_arg_pre + fmt_arg + fmt_arg_suf

        return fmt_full_arg

    def fmt_filepath(self, arg: str):

        slashindex = arg.find("/")
        if slashindex >= 0:
            potential_path = arg[slashindex:]
            prefix = arg[:slashindex] # save non-folder prefix

            potential_path_last_slash = potential_path.rfind("/") + 1 # color folder differently
            potential_path_last = potential_path[potential_path_last_slash:]
            potential_path_folder = potential_path[:potential_path_last_slash]

            if os.path.islink(potential_path_folder):
                fmtdir = self.fs_lnk.fgfmt(potential_path_folder, True)
            elif os.path.isdir(potential_path_folder):
                fmtdir = self.fs_dir.fgfmt(potential_path_folder, True)

            fmt

            print(f"Folder: {potential_path_folder}, last: {potential_path_last}")
            # it could be a file, idk
            if not os.path.exists(potential_path):
                fmtstr = self.ps_args.fgfmt(potential_path)
            elif os.path.islink(arg):
                fmtstr = self.fs_lnk.fgfmt(potential_path)
            elif os.path.isdir(arg):
                fmtstr = self.fs_dir.fgfmt(potential_path)
            elif os.path.isfile(potential_path):
                if os.access(potential_path, os.X_OK):
                    fmtstr = self.fs_exe.fgfmt(potential_path, True)
                else:
                    fmtstr = self.ps_args.fgfmt(potential_path, True)
            else:
                fmtstr = self.ps_args.fgfmt(potential_path)
            fmtstr = self.ps_args.fgfmt(prefix) + fmtstr
        else:
            fmtstr = self.ps_args.fgfmt(arg)

        return fmtstr

    def force_add_fmtstr_to_cache(self, textstr: str, fmtstr: str):
        self.fmtcache[textstr] = fmtstr

    def fmt_arg_if_not_exists(self, arg: str):
        if arg in self.fmtcache:
            fmtarg = self.fmtcache[arg]
        else:
            fmtarg = self.ps_args.fgfmt(arg)
            self.fmtcache[arg] = fmtarg
        return fmtarg

# def strfmt(color: str, content: str):
#     return f"\x1b[0;{color}m{content}\x1b[0m"

def procfmt(config: ColorConfig):
    for proc in psutil.process_iter():
        with proc.oneshot():

            pid = proc.pid
            name = proc.name()
            status = proc.status()
            # username = proc.username()

            if status == 'zombie':
                commandline = []
            else:
                try:
                    exe = proc.exe()
                except:
                    exe = ""

                commandline = proc.cmdline()
                fmtcmdline = deque(commandline)

                if (len(commandline) > 1):
                    if (exe == ""):
                        fmtcmdline.appendleft("(-)")
                        if (commandline[0] != exe):
                            fmtcmdline.appendleft(exe)
                        else:
                            fmtcmdline.appendleft(exe)

                    for i in commandline:
                        fmtcmdline.append(config.color_cmd_arg(i))

                    commandline[1] = f"({commandline[1]})"

            return (pid, name, status, commandline)

config = ColorConfig()

pathtests = [
    "/org/gtk/gvfs/exec_spaw/1", # dconf path, does not exist
    "--flatpak=/app/lib/firefox/firefox-bin", # flatpak path
    "/home/vlk/.config/bar-scripts/supergfx-status.sh", # script
    "--bin=/opt/vscodium-bin/codium", # binary
    "/home/vlk/bin", # symlink
    "[kworker/u32:3-btrfs-endio-write]", # kernel proc
    "--ozone-platform=wayland", # random arg
]
for i in pathtests:
    print(config.color_cmd_arg(i))
# fmtstr = procfmt(colors)
