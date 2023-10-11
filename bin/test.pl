#!/usr/bin/perl
use strict;
use warnings;
use v5.36;

my @failed_deps = grep { system("command -v $_ >/dev/null 2>&1") != 0 }
  ( "pidstat", "fzf", "dircolors", "pstree" );
die "Error, missing dependencies: " . join( " ", @failed_deps ) . "\n"
  unless ( scalar(@failed_deps) == 0 );

my $lscolors_cmd = "lscolors";
$lscolors_cmd = "ls -d --color=always"
  unless ( system("command -v lscolors >/dev/null 2>&1") == 0 );

unless ( defined $ENV{"LS_COLORS"} ) {
    print "LS_COLORS is not set. Setting them now.\n";

    # C-shell output is easier to parse through
    my $dir_colors = `dircolors -c`;
    die "Error finding dir colors! Exit code: $?\n" unless ( $? == 0 );
    $dir_colors =~ s/^setenv LS_COLORS '([^']+)'/$1/;

    # $dir_colors =~ s/'$//;
    print $dir_colors;
    $ENV{"LS_COLORS"} = $dir_colors;
}

my ($dir_color) = $ENV{"LS_COLORS"} =~ /:di=([^:]+)/;

sub colorize {
    my $colored = $_;
    if ( -e $_ ) {

        # warn "Colorizing $_\n";
        $colored = `lscolors '$_'`;
        $colored =~ s/\n//g;
    }
    else {
        my ($basename) = $_ =~ /(.+)\/.+$/;
        my ($fname)    = $_ =~ /\/([^\/]+)$/;
        if ( !defined $basename ) {
            $colored = $_;
        }
        elsif ( -e $basename ) {
            $colored = "\e[0;${dir_color}m$basename/\e[0m${fname}\e[0m";
        }
        elsif ( $_ =~ /^\/app.*/ ) {
            $colored = "\e[0;${dir_color}m$basename/\e[0;1m${fname}\e[0m";
        }
    }
    return $colored;
}

my %colorpaths = ();
my $paths =
"/bin/bash /app/bin/discord /app/discord/Discord ///bin/sh --type=zygote jj/usr/bin/ba\"sh --no-zygote-sandbox file:///run/user/1000/doc/5c298551/Phil%20Rel%20A3%20FR1.doc (/usr/bin/bash) /bin/sh /usr/bin/entrypoint /usr/bin/bash --verbose type='signal',sender='org.freedesktop.UPower',path='/org/freedesktop/UPower/devices/line_power_ACAD',interface='org.freedesktop.DBus.Properties' --config-file=/usr/share/defaults/at-spi2/accessibility.conf";

my @display_args        = ();
my $path_disp_color     = "\e[0;1;91m";
my $surround_disp_color = "\e[91m";
foreach ( split( /\s+|\t+/, $paths ) ) {
    next unless ( $_ =~ /\/+/ );
    my ($parsed) = $_ =~ /(\/[^\/][^\s]+)/;       # |file:\/\/[^\s]+
    my $colorparsed = $parsed;

    # if ( -e $parsed ) {
    #     $colorparsed = colorize($parsed);
    # }
    if ( defined $colorpaths{$parsed} ) {
        print "Skipping colorizing path $parsed\n";
        $colorparsed = $colorpaths{$parsed};
    }
    elsif ( $parsed =~ /"/ ) {
        $colorparsed = "${path_disp_color}$parsed\e[0m";
    }
    else {
        my ($shencoded) = $parsed =~ s/"//g;
        $colorparsed = `$lscolors_cmd "$parsed"`;
        $colorpaths{$parsed} = $colorparsed;
    }
    $colorparsed =~ s/\e\[0m/$path_disp_color/g;
    $colorparsed =~ s/\n/\e\[0m/g;
    $_           =~ s/\Q$parsed\E/$colorparsed/g;
    push( @display_args, "${surround_disp_color}$_\e[0m" );
}
print join( "\n", @display_args );
