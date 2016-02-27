use strict; use warnings;
use GnuPG qw(:algo);
use File::Basename;
use File::Spec;

use IO::Async::Loop;
use Net::Async::CassandraCQL;
use Protocol::CassandraCQL qw/CONSISTENCY_QUORUM/;

my $loop = IO::Async::Loop->new;
my $cass = Net::Async::CassandraCQL->new(
    host                => 'localhost',
    keyspace            => 'rootcrit',
    default_consistency => CONSISTENCY_QUORUM,
);
$loop->add($cass);
$cass->connect->get;

my $gpg = new GnuPG();
if (scalar(@ARGV) == 0) {
    warn "You need to specify a filename!";
}
else {
    my $whole_path = $ARGV[0];
    my $input_filename = basename($whole_path);
    my $encrypted_path = dirname($whole_path);
    if ($encrypted_path eq '.') {
        $encrypted_path = './';
    }
    my $extension = '.gpg';
    my $output_filename = $input_filename . $extension;
    my $output_whole_path = File::Spec->catfile($encrypted_path,$output_filename);
    warn "output file name $output_filename";
    warn "encrypted path $encrypted_path";
    warn "Encrypting $whole_path";
    warn "Output $output_whole_path";
    $gpg->encrypt(
        plaintext => $whole_path,
        output    => $output_whole_path,
        recipient => 'Rootcrit',
    );
    unlink($whole_path);
    my $upload_encrypted_file_statement = $cass->prepare(
    "INSERT INTO incidents (
        incident_id,
        filename,
        image,
        location
    ) VALUES (
        uuid(),
        ?,
        ?,
        ?
    );")->get;
    my $encrypted_file_blob = undef;
    open(my $encrypted_filehandle, $output_whole_path) or die $!;
    read($encrypted_filehandle, $encrypted_file_blob, -s $encrypted_filehandle);
    my $x = $cass->execute($upload_encrypted_file_statement, [$output_filename, $encrypted_file_blob, 'home'])->get;
}
