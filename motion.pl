#!/usr/bin/env perl
# This script is used to create the motion.conf template automatically for you.
use Tenjin;
use File::Slurp;
use File::Spec;
use Try::Tiny;

use 5.18.2;

# Get the current working directory
my $current_directory = File::Spec->curdir;

# If we find the config file here, it's the rootcrit directory
# Find the rootcrit config file
my $rootcrit_config_file = $ARGV[0] // 'rootcrit.conf';
my $result = try {
    my $result = { status => 'failed' };
    my $config_text = read_file($rootcrit_config_file);
    $result->{status} = 'succeeded';
    $result->{config} = eval $config_text;
    return $result;
}
catch {
    my $err = $_;
    warn $err;
    return {
        status => 'failed',
    };
};
if ($result->{status} eq 'succeeded') {
    my $fh = $result->{filehandle};
use Data::Dumper; local $Data::Dumper::Maxdepth = 2;
    warn Dumper $result->{config};
    
    say "$result->{config}->{username} - we found the rootcrit config file";
    say "Now attempting to find the rootcrit transmit perl script";

    # Find the transmit.pl file
    my $transmit_file = "transmit.pl";
    # Use curdir to get the absolute path for our template
    # Look up the gpg file path
    # Look up the motion default template file
    # Compute it using Tenjin
        # provide parameters that we've gathered here to Tenjin here
    # Take the output and write it to a config file
}
# Otherwise we need to stop here and ask the user to re-orient us
    # print the usage here
else {
}
