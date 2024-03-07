#!/usr/bin/zsh
# A script by vlk that emulates 'rofi -show drun' but is implemented in zsh and shows all desktop entries regardless of their display status or whatever.
# It is primarily intended to teach people how to script using zsh features.

set -e # set 'errexit'. If an error is encountered and is not handled, the script exits.

# in zsh, for some reason, the creator added 'foreach' syntax, I'm guessing to try and make it look more like perl. This loops over every element in a dynamically created array
# and behaves exactly like a 'for i in val1 val2; do ...; done' loop. This script uses these a lot.
# It is ALWAYS good practice to make sure that we have all the required commands.
# If someone is running this on BSD or mac, they may not have them at all, or they may have the shitty BSD clones. This is def something to watch out for and can result in undefined behavior.
foreach i (grep rofi tr bash zsh) {
    # check if we have the command. Yeet both STDOUT and STDERR into the V O I D (found at /dev/null on most unix-like systems).
    # This should return 0 (success, true, whatever) if you have the command, and return 1 (error, false, whatever) if you don't have it.
    # 'command || othercommand' will make 'othercommand' run if 'command' returned false.
    command -v $i &>/dev/null || faildeps+=("$i")
}
# If the faildeps array is set, then print the missing dependencies and exit. chained '&&' commands will execute down the line until one of them returns false.
# I always set variables with default values, but this is an exception because it is an example of testing if an array is actually set.
# 'print -l' will print each argument on a new line. the 'print' shell builtin will recognize array values and print all the elements even if
# all elements are not explicitly stated (for example, $arr[@] or ${(@)arr}). Array elements specified by key can be printed with $array[$key].
# in zsh, you don't need to quote variables most of the time, except in certain rare cases where quoting will produce a different output.
# If arrays are quoted like "$array", this joins all the elements into a single string joined with IFS like "${array[*]}" from bash. use option KSH_ARRAYS to disable this useful behavior.
(($+faildeps)) && print -l "Error, missing dependencies!" $faildeps && exit 1

# set -u forces the script to exit if an undefined variable is encountered. This helps prevent foolish runtime errors. This will take affect for all code that comes after this.
set -u

# set the value of $selection to the STDOUT output of the subshell.
selection="$(
    # ( commands; ) is a subshell. This is a shell within the shell that does not affect anything outside of itself. Useful for "sandboxing" variables, but has microscopic performance overhead
    (
        # create a new associative array (hash map). I always set variables with default values to prevent unwanted errors.
        typeset -A desktops=()
        # splits XDG_DATA_DIRS into an array using : as a delimiter, adds '/applications/*.desktop(N-.)' to the end of each element, then ~ at the front makes zsh expand the path glob.
        # the (N) makes it not fail if it finds zero matches, and the (-.) makes it only match files and symlinks to files. This excludes sneaky directories that end with .desktop
        foreach desktop_entry (${~${(s.:.)XDG_DATA_DIRS}//%/\/applications/*.desktop(N-.)}) {
            # This removes the parent directory of $desktop_entry, leaving the :t 'tail' of the filepath, then it takes that result and removes the .desktop file extension.
            # If you felt like resolving symlinks, you can use ${var:A} to do so.
            key="${desktop_entry:t:r}"
            # if $desktops[key] is set, then skip parsing the file.
            # 'command && othercommand' will make 'othercommand' run only if 'command' returns true.
            # Note that command && othercommand || someothercommand can run 'someothercommand' sometimes even if 'othercommand' returned true. This is a common cause of undefined behavior.
            ((${+desktops[$key]})) && continue

            myicon='' myexec='' myname='' line='' # reset on each iteration so we don't persist state
            # ${var:-} uses '' in place of $var if it is empty or undefined, ':=' sets the variable's value to the placeholder string if it is empty or undefined.
            # This is really only necessary when 'set -u' (where undefined variables cause an error), but
            # [[ -z ${var:-} ]] returns false if it is empty or undefined. You don't need to quote variables inside double-bracket test commands
            while read -r line; do
                case "${line:=}" in
                    # if line starts with a specified key, set the corresponding property
                    # I have a habit of always obsessively quoting everything I carry over from other shell languages. You don't need to do so in zsh, but it can't really hurt *too* much now, can it?
                    Icon=*) [[ -z ${myicon:-} ]] && myicon="$line" ;;
                    Name=*) [[ -z ${myname:-} ]] && myname="$line" ;;
                    Exec=*) [[ -z ${myexec:-} ]] && myexec="$line" ;;
                esac
                # </file/path passes a file to stdin, line by line. <() shell constructs run a command and put its output into a tempfile.
                # These tempfiles are names like '/proc/self/fd/12' and are a way to use shell commands that don't take input from stdin.
                # One could argue I could easily run 'grep file | while read -r line; do...; done', but the loop in that case is in
                # its own separate subshell and thus I cannot modify any variables outside of the immediate scope.

                # I run | tr '\t' '    ' || : here to remove tabs (my chosen IFS) and replace them with a sane spacing default.
                # if the file is empty or doesn't have all the keys, ':' will make it still return 0 so the script can continue.
            done < <(grep -E '^(Name|Icon|Exec)=' "$desktop_entry" 2>/dev/null | tr '\t' '    ' || :)
            # using tab as my IFS (internal field separators). In many cases it is smarter to use nullbytes (\0) because literally no one types them at all ever, but since rofi uses them internally, it's better to be safe than sorry.
            desktops+=(["$key"]="${myicon:-}"$'\t'"${myname:-}"$'\t'"${myexec:-}")
        }

        # safely back up my IFS even though it's in a subshell so it doesn't really matter very much
        OLDIFS="${IFS:-}"
        # Internal Field Separators are a list of characters the shell interprets as word-splitting. By default in zsh, IFS is $' \t\n\C-@'
        # If you ever notice anyone write 'variable="thing1 thing2 thing3"; for i in $variable; do...; done' they are using IFS to split the variable into an array.
        # This POSIX behavior is the reason why we always quote our variables in shell languages. In zsh however, you don't HAVE to quote variables because it does not do this splitting unless told to.
        IFS=$'\t'
        foreach entry (${(@v)desktops}) { # only get the values of the hash table
            # make entry_content a hash table so it's easier to get desired elements
            local -A entry_content=()
            # split $entry into args using IFS (sh word split)
            foreach j (${=entry}) {
                declare "entry_content[${j%%=*}]=${j#*=}"
            }
            # name and command are split with a tab, because rofi doesn't let you have hidden content in -dmenu mode
            # Command has the %F %u parameters removed because those are meant to be files and URLs, and we don't need those here. Flatpak entries have '@@' all over the place but they can handle it
            # each item has a placeholder fallback just in case it is missing a field. if the Icon field is set and not empty, then it will print the icon using the rofi icon syntax. If not, then it will skip.
            echo "${entry_content[Name]:-UNNAMED}"$'\t'"${${entry_content[Exec]:-false}%\%[FfUu]*}${entry_content[Icon]:+\\0icon\\x1f$entry_content[Icon]}"
            unset entry_content # unset so we don't get random-ass shit from the previous entry
        }
    ) | rofi -dmenu -mesg "Showing ALL desktop entries"
)"
[[ -n "${selection:-}" ]] # return true if the selection is set and defined, otherwise return false and automatically exit

# use bash to execute the desktop icon stuff because your distro probably has bash symlinked to /bin/sh anyways, and dash/ash/ksh as sh could result in untested/undefined behavior
# 'exec' replaces this script's process with the specified command. In this case, it replaces the script with the command you selected.
exec bash -c "${selection#*$'\t'}"

# masochistic enough to make it to the end? Check out some of these resources.
#
# https://wiki.archlinux.org/title/Zsh  -- read this if you want to join the cult of zsh
# https://github.com/rothgar/mastering-zsh  -- a repo I found that has some good info
# https://zsh.sourceforge.io/Doc/Release/zsh_toc.html  -- the manpages, but in a much easier format to read
# https://github.com/REALERvolker1/homescripts/tree/main/.config/zsh  -- my own dotfiles for zsh
# https://dev.to/z-shell/zsh-native-scripting-handbook-2037
#
# https://github.com/dylanaraps/pure-bash-bible  -- This isn't *specifically* for zsh, but it's very useful for other shell languages, plus they made one for POSIX sh too
# https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap09.html#tag_09_04  -- VERY dry reading, but can be useful for learning regex
# https://command-not-found.com/  -- use this if you don't feel like downloading one of those slow packagekit "find the command" command not found hook things

