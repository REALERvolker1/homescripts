#!/usr/bin/perl
# pacman package searching thingy, by vlk
use strict;
use warnings;
use v5.36;

my %fmts = (
    'core'        => 3,
    'extra'       => 2,
    'multilib'    => 6,
    'g14'         => 5,
    'aur'         => 4,
    'chaotic-aur' => 1,
);

sub panic {
    my $retstr = "";
    foreach (@_) {
        $retstr = "$retstr\n" unless ( $retstr eq "" );
        $retstr = "$retstr$_";
    }
    die "$retstr\n" unless ( $retstr eq "" );
}
panic( "Error, undefined variable", "XDG_RUNTIME_DIR" )
  unless ( defined $ENV{'XDG_RUNTIME_DIR'} );

my $PKGCACHE     = "$ENV{'XDG_RUNTIME_DIR'}/pacs";
my $PKGCACHEFILE = "$PKGCACHE/cachefile.cache";
my $PKGRUN       = "$PKGCACHE/runfile.run";

sub refresh {
    mkdir($PKGCACHE) unless ( -e $PKGCACHE );
    print "Refreshing package cachefiles...\n";
    open( FH, '>', $PKGCACHEFILE ) or die $!;
    my @filtered_pacman_output;
    my $pacman_output = `pacman -Si`;
    my @wrk;
    foreach ( split( "\n", $pacman_output ) ) {
        next if ( $_ =~ /^Archi.*x86_64$/ );
        next unless ( $_ =~ /^(Repository|Name|Version|Description).*/ );
        $_ =~ s/[\t\s]+/ /g;    # tabs are our IFS
        if ( $_ =~ /^(Repository).*/ ) {
            push( @filtered_pacman_output, join( "\t", @wrk ) );
            @wrk = ();
        }
        push( @wrk, $_ );
    }
    foreach my $pkg (@filtered_pacman_output) {
        my @package = split( "\t", $pkg );
        my @pkgfmt;
        my $pkgnameprefix = 'NULL';
        foreach (@package) {
            next unless ( $_ =~ /^.+:.+$/ );
            my ($key) = $_ =~ /^([^:\s]+)/;
            my ($val) = $_ =~ /\s*([^:]+)$/;
            if ( $key eq "Repository" ) {
                my $fmtstr;
                if ( defined( $fmts{$val} ) ) {
                    $fmtstr = "3$fmts{$val}";
                }
                else {
                    $fmtstr = 0;
                }
                push( @pkgfmt, "\e[0;${fmtstr}m$val" );
            }
            elsif ( $key eq "Name" ) {
                $pkgnameprefix = $val;
                push( @pkgfmt, "\e[0;1m/$val" );
            }
            elsif ( $key eq "Version" ) {
                push( @pkgfmt, "\e[0;36m $val" );
            }
            elsif ( $key eq "Description" ) {
                push( @pkgfmt, "\e[0;2m $val\e[0m" );
            }
        }
        my $pkgstr = "$pkgnameprefix=" . join( "", @pkgfmt );
        print FH "$pkgstr\n" unless ( $pkgstr eq '=' );
    }
    close(FH);
    print "Cachefiles successfully refreshed!\n";
}

# dependency checking
my @faildeps;
foreach ( "pacman", "fzf" ) {
    push( @faildeps, $_ )
      unless ( system("command -v $_ >/dev/null 2>&1") == 0 );
}
panic( "Error, missing dependencies,", @faildeps ) unless ( !@faildeps );

my $arg_update  = 0;
my $arg_preview = 0;
my $onlyshow    = "not-installed";
my @queryarr;
foreach (@ARGV) {
    if ( $_ eq '--update' or $_ eq '-u' ) {
        $arg_update = 1;
    }
    elsif ( $_ eq '--installed' or $_ eq '-i' ) {
        $onlyshow = "installed";
        print "Only showing installed packages\n";
    }
    elsif ( $_ eq '--all' or $_ eq '-a' ) {
        $onlyshow = "all";
        print "Showing all packages\n";
    }
    elsif ( $_ =~ /^-.*/ ) {
        panic( "Error, argument '$_' is not supported!", "", "Options:" );
    }
    else {
        $_ =~ s/\'/\'\\\'\'/g;
        push( @queryarr, $_ );
    }
}
refresh if ( !-e $PKGCACHEFILE ) or ( $arg_update == 1 );

open( FH, '<', $PKGCACHEFILE ) or die $!;

# use a hash so lookup is O(1)
my %packages;
while (<FH>) {
    chomp($_);
    my ($name)   = $_ =~ /^([^=]+)/;
    my ($fmtstr) = $_ =~ /^[^=]+=(.*)/;
    $packages{$name} = $fmtstr;
}
close(FH);

my @installedpkgs;
foreach ( split( "\n", `pacman -Q` ) ) {
    my ($tmpname) = $_ =~ /^([^\s]+)\s/;
    if ( defined( $packages{$tmpname} ) ) {
        if ( $onlyshow eq "not-installed" ) {
            delete( $packages{$tmpname} );
        }
        else {
            if ( $onlyshow eq "installed" ) {
                push( @installedpkgs, $packages{$tmpname} );
            }
            else {
                $packages{$tmpname} = "\e[1;32m[i]\e[0m $packages{$tmpname}";
            }
        }
    }
}

# workaround for `Can't exec "/bin/sh": Argument list too long`
my $packagesfilestr;
if ( $onlyshow eq "installed" ) {
    $packagesfilestr = join( "\n", @installedpkgs );
}
else {
    $packagesfilestr = join( "\n", values(%packages) );
}
open( FH, '>', "$PKGRUN" ) or die $!;
print FH "$packagesfilestr\n";
close(FH);

my $querystr = '';
$querystr = "-q '" . join( " ", @queryarr ) . "' " if ( defined $queryarr[0] );

my $pkgsel =
`fzf ${querystr} --ansi --preview="pacman -Si \\\$(echo {} | grep -oP '^[^/]+/\\K[^[:space:]]+')" --header='Use \e[1mTAB\e[0m to select multiple packages' --multi <'$PKGRUN'`;
chomp($pkgsel);

panic("No packages selected") unless ( $pkgsel ne "" );
my @selected_packages = map {
    my ($pkgname) = $_ =~ /[^\/]+\/([^\s]+)/;
    $pkgname
} split( "\n", $pkgsel );

my $selstr = join( " ", @selected_packages );

my $info = `pacman -Si $selstr`;
chomp($info);
$info =~ s/(^|\n)([^:]+\s*)/\n\e[0;1m$2\e[0m/g;
print "$info\n";

my $action;
if ( $onlyshow eq "installed" ) {
    $action = "remove";
}
else {
    $action = "install";
}

unless ( system("sudo -vn 2>/dev/null") == 0 ) {
    print "\e[1m[\e[31mSUDO REQUIRED\e[0;1m]\e[0m
Do you want to \e[1m${action}\e[0m these packages?

\e[1m$selstr\e[0m

[y/N] > \e[1m";

    while (<STDIN>) {
        print "\e[0m";
        exit(1) unless ( $_ eq "y\n" );
        last;
    }
}
if ( $action eq "install" ) {
    system("sudo pacman -S --needed $selstr");
}
elsif ( $action eq "remove" ) {
    system("sudo pacman -Rcs $selstr");
}
