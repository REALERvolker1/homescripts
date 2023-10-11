#!/usr/bin/perl
# psa.pl, by vlk
# https://github.com/REALERvolker1/homescripts
use strict;
use warnings;
use v5.36;

sub checkcmd {
    my @nullcmds = ();
    foreach (@_) {
        push( @nullcmds, $_ )
          unless system("command -v $_ >/dev/null 2>&1") == 0;
    }
    return @nullcmds;
}

# sudo dnf install sysstat fzf coreutils lscolors
# system("command -v $_ >/dev/null 2>&1")
# my @failed_deps =
#   grep { checkcmd($_) != 0 } ( "ps", "pidstat", "fzf", "dircolors", "pstree" );
my @failed_deps = checkcmd( "ps", "pidstat", "fzf", "dircolors", "pstree" );

die
"Install the following binaries using your distribution's package manager: \n\e[1m"
  . join( " ", @failed_deps )
  . "\e[0m\n"
  . "(eg: sudo dnf install sysstat fzf coreutils lscolors)\n"
  unless scalar(@failed_deps) == 0;

my $lscolors = "lscolors";
unless ( checkcmd($lscolors) == 0 ) {
    warn "binary 'lscolors' not found. Falling back to 'echo'\n";
    $lscolors = "echo";
    warn
"You can install it with '\e[0;1;92mcargo\e[0;1m install \e[0;1;93mlscolors\e[0m'\n"
      if ( checkcmd("cargo") == 0 );
}

unless ( defined $ENV{"LS_COLORS"} ) {
    print "LS_COLORS is not set. Setting them now.\n";

    # C-shell output is easier to parse through
    my $dir_colors = `dircolors -c`;
    die "Error finding dir colors! Exit code: $?\n" unless $? == 0;
    $dir_colors =~ s/^setenv LS_COLORS '([^']+)'/$1/;

    # $dir_colors =~ s/'$//;
    print $dir_colors;
    $ENV{"LS_COLORS"} = $dir_colors;
}

# my ($dir_color) = $ENV{"LS_COLORS"} =~ /:di=([^:]+)/;

my @procs      = ();
my %colorpaths = ();
my $output_str = "";

my $path_disp_color = "\e[0;1;91m";
print "Formatting processes...\n";
foreach ( split( "\n", `ps -eo '%p\t%c\t' -o exe -o '\t%a'` ) ) {
    my ( $pid, $name, $comm, $args ) = split( /\s*\t\s*/, $_ );

    # This makes sure that you always see the full command path and args

    # Skip kernel processes. Killing these would be foolish
    next if ( $args =~ /^\[[^\]]*\]$/ );
    $pid =~ s/\s*//;

    # next if ( $pid =~ /\s*PID/ );
    $name =~ s/^\s+|\s+$//g;
    $comm =~ s/^\s+|\s+$//g;
    $args =~ s/^\s+|\s+$|\n//g;

    # You don't need to see the same thing twice if you don't have to
    if ( $args =~ /^\s*$|^$comm$/ ) {
        $args = $comm;
    }
    elsif ( $args =~ /^\s*$comm/ ) {
        $args =~ s/^\s*\Q$comm\E\s*//;
        $args = "$comm $args";
    }
    elsif ( $comm =~ /^\s*-\s*$/ ) { }
    else {
        # $args = "($comm) $args";
        $args =~ s/^\s*([^\s]+)/\($1\) $comm/;
    }
    my $procstr      = "$pid\t$name\t$args";
    my @colored_args = ();
    if ( $args =~ /<defunct>$/ ) {
        $name =~ s/\s*<defunct>\s*//;
        push( @colored_args, "\e[93m<defunct> $args\e[0m" );
    }
    else {
# I want to see LS_COLORS. I spent a damn long time on my config and so I need to feel like it meant something
        foreach ( split( /\s+|\t+/, $args ) ) {
            unless ( $_ =~ /\/+/ ) {
                push( @colored_args, "\e[32m$_\e[0m" );
                next;
            }
            my ($parsed) = $_ =~ /(\/[^\/][^\s]+)/;       # |file:\/\/[^\s]+
            my $colorparsed = $parsed;

            if ( defined $colorpaths{$parsed} ) {
                $colorparsed = $colorpaths{$parsed};
            }
            elsif ( $parsed =~ /"/ ) {
                $colorparsed = "${path_disp_color}$parsed\e[0m";
            }
            elsif ( $parsed =~ /^\/app/ ) {
                $colorparsed = "\e[0;1;95m$parsed\e[0m";
            }
            else {
                my ($shencoded) = $parsed =~ s/"//g;
                $colorparsed = `$lscolors "$parsed"`;
                $colorpaths{$parsed} = $colorparsed;
            }
            $colorparsed =~ s/\e\[0m/$path_disp_color/g;
            $colorparsed =~ s/\n/\e\[0m/g;
            $_           =~ s/\Q$parsed\E/$colorparsed/g;
            push( @colored_args, "\e[1;32m$_\e[0m" );
        }
    }
    $output_str .=
      "\e[1;93m$pid\e[0;96m\t$name\e[0m\t" . join( " ", @colored_args ) . "\n";
    push( @procs, $procstr );
}
$ENV{"S_COLORS"} = "always";

# $output_str =~ s/^\s*\n$//;
chomp($output_str);
my $pidstat = "pidstat --human -lRtU -p";

# my $chosen =
# `fzf --ansi --preview-window='down,25%' --header-lines=1 --preview=\"$pidstat \\\$(echo {} | sed 's|\\\t.*||')\" <<< "$output_str"`;
my $chosen =
`echo "$output_str" | fzf --ansi --preview-window='down,25%' --header-lines=1 --preview=\"$pidstat \\\$(echo {} | sed 's|\\\t.*||')\"`;
die "Error, no process selected!\n"
  unless ( defined $chosen && $chosen =~ /[^\s]+/ );

chomp($chosen);

# $chosen =~ s/\n//g;

my ( $pid, $name, $args ) = split( /\s*\t\s*/, $chosen );

my $owner = `ps -o user -p $pid`;
$owner =~ s/^USER|\n+//g;

# https://github.com/REALERvolker1/homescripts
my %actions = (
    stat => "1: \e[94mGet statistics (pidstat)\e[0m",
    echo => "2: \e[95mPrint process details\e[0m",
    tree => "3: \e[92mGet process tree (pstree)\e[0m",
    kill => "4: \e[91mKill process (kill)\e[0m",
);
delete $actions{"kill"} if ( $owner ne $ENV{"USER"} );

my $action_str = join(
    "\n",
    sort {
        my ($anum) = $a =~ /^(\d+)/;
        my ($bnum) = $b =~ /^(\d+)/;
        $anum <=> $bnum;
    } values %actions
);

my $action = `echo '$action_str' | fzf`;
$action =~ s/^([0-9]+).*\n/$1/;

my $cmd_output = "PID: $pid\nNAME: $name\nARGS: $args";
if ( $action =~ /^\s*$/ ) {
    $cmd_output = "No action specified. Exiting";
}
elsif ( $actions{"stat"} =~ /^$action/ ) {
    $cmd_output = `$pidstat '$pid'`;
}
elsif ( $actions{"echo"} =~ /^$action/ ) { }
elsif ( $actions{"tree"} =~ /^$action/ ) {
    $cmd_output = `pstree -sp '$pid'`;
}
elsif ( $actions{"kill"} =~ /^$action/ ) {
    print
"Are you sure you want to \e[1;91mKILL\e[0m this process?\n$cmd_output\n[y/N] > ";
    my $ans = <STDIN>;
    chomp($ans);
    system("kill $pid") if ( $ans eq "y" );
    $cmd_output = "Received answer: '$ans'";
}
else {
    $cmd_output = "Error, invalid action specified!";
}
chomp($cmd_output);
print "$cmd_output\n";
