#!/usr/bin/env perl
# This script is used to create the motion.conf template automatically for you.
use Tenjin;
use File::Slurp;
use File::Spec;
use Try::Tiny;

use 5.18.2;

$Tenjin::USE_STRICT = 1; $Tenjin::ENCODING = 'UTF-8';

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
    
    say "$result->{config}->{username} - we found the rootcrit config file";
    say "Now attempting to find the rootcrit transmit perl script";

    # Look up the gpg file path
    my $gpg_file_path = $result->{config}->{motion_gpg_public};
    # Find the transmit.pl file
    my $transmit_file = "transmit.pl";
    # Look up the motion default template file
    # Join current directory with $default_template
    my $default_template = 'motion.default.conf';
    my $transmit_file_path = File::Spec->rel2abs($transmit_file);
    my $default_template_path = File::Spec->rel2abs($default_template);
    # Compute it using Tenjin
    my $t = Tenjin->new();
    # provide parameters that we've gathered here to Tenjin here
    my $template_variables = {
        on_picture_save     => "$transmit_file_path %f",
        webcam_motion       => 'on',
        webcam_localhost    => 'off',
        webcam_limit        => 0,
    };
    # Take the output and write it to a config file
    my $output = $t->render($default_template_path, $template_variables);
    my $output_filename = 'motion.conf'; 
    open(my $output_fh, '>', $output_filename);
    say "Writing output to $output_filename";
    print $output_fh $output;
}
# Otherwise we need to stop here and ask the user to re-orient us
    # print the usage here
else {
}
