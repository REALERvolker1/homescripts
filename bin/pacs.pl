#!/usr/bin/perl
# pacman package searching thingy, by vlk
use strict;
use warnings;
use v5.36;

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

my @faildeps;
foreach ( "pacmand", "fzfd" ) {
    my $retval = system("sh -c 'command -v $_' >/dev/null 2>&1");
    push( @faildeps, $_ ) unless ( $retval == 0 );
}
panic( "Error, missing dependencies,", @faildeps )
  if ( length( scalar(@faildeps) ) > 1 );

my @fields = ( "Repository", "Name", "Version", "Description", "Architecture" );

my $PKGCACHE = "$ENV{'XDG_RUNTIME_DIR'}/pacs.cache";
my @cache_keys;
my $isCached = 'Undefined';

if ( -e $PKGCACHE && !defined $ENV{"PACS_UPDATE_PKGCACHE"} ) {
    open( my $pkfh, '<', $PKGCACHE )
      or panic("Could not open file: $PKGCACHE");

    while (<$pkfh>) {
        chomp($_);
        push( @cache_keys, $_ );
    }
    $isCached = 'Read from cachefile';
}
else {
    my $pacman_info  = `pacman -Si`;
    my $fields_orstr = join( "|", @fields );
    foreach ( split( "\n", $pacman_info ) ) {
        push( @cache_keys, $_ )
          if ( $_ =~ /^($fields_orstr).*/ );
    }
    open( my $pkfh, '>', $PKGCACHE ) or panic("Could not open file: $PKGCACHE");
    foreach (@cache_keys) {
        print $pkfh "$_\n";
    }
    close $pkfh;
    $isCached = 'Pulled with pacman';
}

my $firstkey = $fields[0];
my @packages;
my @tmp_package;
foreach (@cache_keys) {
    my ($key) = $_ =~ /^\s*([^:\s]+)/;
    my ($val) = $_ =~ /:\s*(.*)\s*$/;
    if ( $key eq $firstkey ) {

        # say "New element joined";
        push( @packages, @tmp_package );
        @tmp_package = ();
    }
    else {
        # $tmp_package->{"$key"} = $val;
        push( @tmp_package, { $key => $val } );
    }

    # say "key: '$key' => '$val'";
}

foreach my $pkg (@packages) {
    say $pkg->{'Name'};
}

print "Is cached: $isCached\n";
