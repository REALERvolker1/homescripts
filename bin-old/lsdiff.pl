#!/usr/bin/perl
# lsdiff.pl, by vlk
# https://github.com/REALERvolker1/homescripts
use strict;
use warnings;
use v5.36;

my $diff_file = "$ENV{'XDG_CACHE_HOME'}/lsdiff.cache";

my $diff_folder = "$ENV{'HOME'}";

my @content = split( "\n",
`lsd --ignore-config -A --group-dirs first --color always --icon always '$diff_folder'`
);

# my @content = split( "\n",
#     `ls --color=always --group-directories-first -A1 '$diff_folder'` );

if ( !defined $ARGV[0] && -f $diff_file ) {
    open( my $in, '<', $diff_file ) or die $!;
    my @fcontent = map { chomp; $_ } <$in>;
    close $in or die "$in: $!";
    my @out = (
        map { "\e[0;1;92m+\e[0m $_" } grep {
            my $el = $_;
            not grep { $_ eq $el } @fcontent
        } @content
    );
    push(
        @out,
        (
            map { "\e[0;1;91m-\e[0m $_" } grep {
                my $el = $_;
                not grep { $_ eq $el } @content
            } @fcontent
        )
    );
    print join( "\n", @out );
    exit(0);
}

if ( ( defined $ARGV[0] && $ARGV[0] eq '--update' ) || !-f $diff_file ) {
    open( my $fh, '>', $diff_file ) or die $!;
    print "Updating...\n";
    print $fh join( "\n", @content );
    close $fh or die "$fh $!";
}
