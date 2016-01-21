use strict; use warnings;
use GnuPG qw(:algo);
use File::Basename;
use File::Spec;
my $gpg = new GnuPG();
if (scalar(@ARGV) == 0) {
    warn "You need to specify a filename!";
}
else {
    my $whole_path = $ARGV[0];
    my $input_filename = basename($whole_path);
    my $encrypted_path = dirname($whole_path);
    if ($encrypted_path eq '.') {
        $encrypted_path = '';
    }
    my $extension = '.gpg';
    my $output_filename = $input_filename . $extension;
    my $output_whole_path = File::Spec->catfile($encrypted_path,$output_filename);
    warn "Encrypting $whole_path";
    warn "Output $output_whole_path";
    $gpg->encrypt(
        plaintext => $whole_path,
        output    => $output_whole_path,
        recipient => 'Rootcrit',
    );
    unlink($whole_path);
}
