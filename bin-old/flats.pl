#!/usr/bin/perl
# pacman package searching thingy, by vlk
use strict;
use warnings;
use v5.36;

my %fmts = (
    'app'         => 3,
    'runtime'     => 2,
    'remote'      => 6,
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

my $PKGCACHE     = "$ENV{'XDG_RUNTIME_DIR'}/flats";
my $PKGCACHEFILE = "$PKGCACHE/cachefile.cache";
my $PKGRUN       = "$PKGCACHE/runfile.run";

sub refresh {
    mkdir($PKGCACHE) unless ( -e $PKGCACHE );
    print "Refreshing package cachefiles...\n";
    open( FH, '>', $PKGCACHEFILE ) or die $!;
    my @filtered_pacman_output;
    my $flatpak_remote_output = `flatpak remote-ls`;
    # print FH "$pkgstr\n" unless ( $pkgstr eq '=' );
    close(FH);
    print "Cachefiles successfully refreshed!\n";
}
