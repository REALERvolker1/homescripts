#!/usr/bin/perl
# a script to remove stuff
use strict;
use warnings;
use v5.36;

use Cwd 'abs_path';
use POSIX qw(strftime);

# use URI::Escape;

sub prompt {
    print join( "\n", @_ ) . "\n";
    my $retval = 0;
    print "[y|N] > ";
    while (<STDIN>) {
        if ( $_ =~ /[yY]/ ) {
            $retval = 1;
        }
        elsif ( $_ =~ /[nN]/ ) {
            $retval = 0;
        }
        elsif ( $_ =~ /[qQ]/ ) {
            die "Exiting...\n";
        }
        else {
            print "[y/N] > ";
            next;
        }
        last;
    }
    return $retval;
}

my @files;
my @errors;
my $TRASH          = 1;
my $STOP_ARGSPARSE = 0;

sub add_file {
    return 1 unless ( defined $_ && $_ ne "" );
    if ( -l $_ ) {
        push( @files, $_ );
    }
    elsif ( -e $_ ) {
        push( @files, abs_path($_) );
    }
    else {
        push( @errors, $_ );
    }
}

foreach (@ARGV) {
    if ( $STOP_ARGSPARSE == 1 ) {
        add_file($_);
    }
    else {
        if ( $_ eq "--delete" ) {
            $TRASH = 0;
        }
        elsif ( $_ eq "--trash" ) {
            $TRASH = 1;
        }
        elsif ( $_ eq "--" ) {
            $STOP_ARGSPARSE = 1;
        }
        elsif ( $_ =~ /-(h|help|-help)/ ) {
            my @helptext = (
'Option flags apply to all files, and option args that come last override previous options',
                '`better-rm --delete file --trash file2` will trash both files',
                '',
                'Available options:',
                '',
                '--delete   permanently delete the specified file',
                '--trash    remove the file to trash (default)',
                '',
'--         all args received after this flag are instead parsed as files.',
                '--help     show helptext',
            );
            print join( "\n", @helptext );
            exit(3);
        }
        else {
            add_file($_);
        }
    }
}

# print join( "\n", @files ) . "\n";

die "Error, could not find files:\n" . join( "\n", @errors ) . "\n"
  if defined( $errors[0] );

if ( ( $TRASH == 1 ) ) {
    foreach my $file (@files) {
        if ( prompt( '', "Send '$file' to trash?" ) == 0 ) {
            print "skipping file $file\n";
            next;
        }
        print "trashing file $file\n";
        my @filestr_arr;
        foreach ( split( "/", $file ) ) {
            push( @filestr_arr, uri_escape($_) );
        }
        my $urlencoded = join( "/", @filestr_arr );
        my $date       = strftime( "%Y-%m-%dT%H:%M:%S", localtime );
        print "[Trash Info]\nPath=$urlencoded\nDeletionDate=$date";

    }
}
else {
    foreach my $file (@files) {
        print "Deleting file $file\n";
    }
}
