#!/usr/bin/perl
use strict;
use warnings;
use v5.36;

my @failed_deps = grep { system("command -v $_ >/dev/null 2>&1") != 0 } ("pidstat", "fzf", "dircolors", "pstree");
die "Error, missing dependencies: " . join(" ", @failed_deps) . "\n" unless (scalar(@failed_deps) == 0);

my $lscolors_cmd = "lscolors";
$lscolors_cmd = "ls -d --color=always" unless (system("command -v lscolors >/dev/null 2>&1") == 0);

unless (defined $ENV{"LS_COLORS"}) {
    print "LS_COLORS is not set. Setting them now.\n";
    # C-shell output is easier to parse through
    my $dir_colors = `dircolors -c`;
    die "Error finding dir colors! Exit code: $?\n" unless ($? == 0);
    $dir_colors =~ s/^setenv LS_COLORS '([^']+)'/$1/;
    # $dir_colors =~ s/'$//;
    print $dir_colors;
    $ENV{"LS_COLORS"} = $dir_colors;
}

my ($dir_color) = $ENV{"LS_COLORS"} =~ /:di=([^:]+)/;


my @procs = ();
my %colorpaths = ();
my $output_str = "";

sub colorize {
    my $colored = $_;
    if (-e $_) {
        # warn "Colorizing $_\n";
        $colored = `lscolors '$_'`;
        $colored =~ s/\n//g;
    }
    else {
        my ($basename) = $_ =~ /(.+)\/.+$/;
        my ($fname) = $_ =~ /\/([^\/]+)$/;
        if (!defined $basename) {
            $colored = $_
        }
        elsif (-e $basename) {
            $colored = "\e[0;${dir_color}m$basename/\e[0m${fname}\e[0m";
        }
        elsif ($_ =~ /^\/app.*/) {
            $colored = "\e[0;${dir_color}m$basename/\e[0;1m${fname}\e[0m";
        }
    }
    return $colored;
}

print "Grabbing current processes...\n";
foreach (split("\n", `ps -eo '%p\t%c\t' -o exe -o '\t%a'`)) {
    my ($pid, $name, $comm, $args) = split(/\s*\t\s*/, $_);
    # next if ($comm =~ /^\s*-\s*$/);
    next if ($args =~ /^\[[^\]]*\]$/);
    $pid =~ s/\s*//;
    $name =~ s/^\s+|\s+$//g;
    $comm =~ s/^\s+|\s+$//g;
    $args =~ s/^\s+|\s+$|\n//g;

    if ($args =~ /^\s*$|^$comm$/) {
        $args = $comm
    }
    elsif ($args =~ /^\s*$comm/) {
        $args =~ s/^\s*\Q$comm\E\s*//;
        $args = "$comm $args";
    }
    elsif ($comm =~ /^\s*-\s*$/) {}
    else {
        # $args = "($comm) $args";
        $args =~ s/^\s*([^\s]+)/\($1\) $comm/;
    }
    my $procstr = "$pid\t$name\t$args";
    my $tmpstr = "$pid\t$name\t";
    my @colored_args = ();
    foreach (split(/\s+/, $args)) {
        my $fmtstr = $_;
        if (-e $_) {
            if (defined $colorpaths{$_}) {
                $fmtstr = $colorpaths{$_};
            }
            else {
                $fmtstr = colorize($_);
                $colorpaths{$_} = $fmtstr;
            }
        }
        push(@colored_args, $fmtstr);
    }
    $output_str .= $tmpstr . join(" ", @colored_args) . "\n";
    push(@procs, $procstr);
}

$output_str =~ s/^\s*\n//;
print "$output_str";




    # my $tmpstr = $procstr;
    # $procstr .= $args;
    # my @paths = ();
    # foreach (split(/\s+|\t+/, $procstr)) {
    #     my $colored_str = $_;
    #     my $index = $_;
    #     if ($_ =~ /^\/.+/) {
    #         # $colored_str = colorize($_);
    #         $index = $_
    #     }
    #     elsif ($_ =~ /^([^=]+)=(\/.*)$/) {
    #         # $colored_str = colorize($2);
    #         $index = $2;
    #     }
    #     elsif ($_ =~ /^\(([^\)]*)\)$/) {
    #         # $colored_str = colorize($1);
    #         $index = $1;
    #     }
    #     my $color = "";
    #     if (defined $colorpaths{$index}) {
    #         $color = $colorpaths{$index};
    #     }
    #     else {
    #         $color = colorize($index);
    #         $colorpaths{$index} = $color;
    #     }
    #     # $colorpaths{$_} if (defined $colorpaths{$_});
    #     $colored_str =~ s/\Q$index\E/$color/g;
    #     # Need to be careful about ansi
    #     # my ($color_before) = $_ =~ s/
    #     push(@paths, $colored_str);
    # }
    # $output_str .= $tmpstr . join(" ", @paths) . "\n";

# my %colorpaths = %{{ map { $_ => colorize($_) } @uniq_paths }};

# foreach (keys %colorpaths) {
#     print "key: $_, val: $colorpaths{$_}\n";
# }
