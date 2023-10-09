#!/usr/bin/perl
use strict;
use warnings;
use v5.36;

my $uptime = `uptime -p`;
$uptime =~ s/^up //;
$uptime =~ s/hour/hr/g;
$uptime =~ s/minute/min/g;
$uptime =~ s/\n//g;

my $disks = `df -h -l -t btrfs -t xfs -t ext4 --output=pcent | uniq`;
$disks =~ s/\n/ /g;
$disks =~ s/Use%\s*//;
$disks =~ s/\s+/ /g;

my $driver_label = "󰏖 Distbx";
my $driver_content = "Unsupported Configuration";
if (defined $ENV{'CONTAINER_ID'}) {
    $driver_content = $ENV{'CONTAINER_ID'};
}
else {
    # I don't feel like installing Arch or Debian to test this out
    # $driver_content = `
    #     if command -v 'rpm' >/dev/null 2>&1; then
    #         rpm -q xorg-x11-drv-nvidia | cut -d '-' -f 5
    #     elif command -v 'pacman' >/dev/null 2>&1; then
    #         pacman -Q nvidia-dkms 2>/dev/null | grep -oP '^.* \\K[^-]*'
    #     elif command -v 'apt' >/dev/null 2>&1; then
    #         apt list 2>/dev/null | grep -m 1 nvidia-driver | cut -d ' ' -f 2
    #     else
    #         echo 'unsupported distro'
    #     fi
    # `;
    my $check_rpm = system("command -v rpm >/dev/null 2>&1");
    if ($check_rpm == 0) {
        $driver_content = `rpm -q xorg-x11-drv-nvidia`;
        $driver_content =~ s/^.*nvidia-//;
        $driver_content =~ s/-.*//;
    }
    $driver_content =~ s/\n//g;
    $driver_label = "󰾲 Nvidia";
}

my $kernel = `uname -r`;
$kernel =~ s/-.*//g;
$kernel =~ s/\n//g;

my @cmds = (
    $ENV{'SHLVL'},
    $uptime,
    $ENV{'TERM'},
    $disks,
    $driver_content,
    $kernel,
);
# idc about having a real hash, I just want to use numerical indices
my @cmd_keys = (
    "94m  SHLVL ",
    "95m 󰅐 Uptime",
    "96m  Term  ",
    "93m 󰋊 Disk  ",
    "92m $driver_label",
    "91m  Kernel",
);
my $cmd_key_length = 8; # Hardcoded for performance

# Run the command and then replace my $user -- this makes it not hardcoded for performance
# my $user_cmd = `figlet -- "$ENV{'USER'}"`;
# my @user = split("\n", $user_cmd);
my @user = (
    "       _ _    ",
    "__   _| | | __",
    "\\\ \\\ / / | |/ /",
    " \\\ V /| |   < ",
    "  \\\_/ |_|_|\\\_\\",
    "              ",
);
my $user_color = 92;
my $user_length = 14;

my $len = 0;
foreach (@cmds) {
    my $ln = length ($_);
    $len = $ln if ($ln > $len);
}

my $box_color = int(rand(256));
$box_color = "\e[0;38;5;${box_color}m";
# ╭┬─╮
# ││ │
# ╰┴─╯

# my $boxtop = "─" x $user_length;
my $boxtop = "${box_color}╭─" . "─" x $user_length . "─┬────" . "─" x $cmd_key_length . "─" x $len . "─╮\e[0m";

print "${boxtop}\n";
my $count = 0;
my $padded_ = "";
foreach my $content (@cmds) {
    $content =~ s/.*$/sprintf("%-${len}s", $&)/e;
    # print "\e[0;38;5;${box_color}m│\e[0;${user_color}m $user[$count] \e[0;38;5;${box_color}m│\e[0;$cmd_keys[$count] \e[1m$_ \e[0;38;5;${box_color}m│\e[0m\n";
    print "${box_color}│\e[0;${user_color}m $user[$count] ${box_color}│\e[0;$cmd_keys[$count]   \e[1m$content ${box_color}│\e[0m\n";
    $count += 1;
}
$boxtop =~ s/╭/╰/g;
$boxtop =~ s/┬/┴/g;
$boxtop =~ s/╮/╯/g;

print "${boxtop}\n";
