use strict; use warnings;
use GnuPG qw(:algo);
use File::Basename;
use File::Spec;

use IO::Async::Loop;
use Net::Async::CassandraCQL;
use Protocol::CassandraCQL qw/CONSISTENCY_QUORUM/;

use Cwd;
use File::Slurp;
my $cwd = getcwd;
my $config_filename = 'rootcrit.conf';
my $config_filepath = File::Spec->catfile($cwd, $config_filename);
my $config_text = read_file($config_filepath);
my $config = eval $config_text;

my $cassandra_host = $config->{cassandra_host};
my $facility = $config->{facility};
my $sensor = $config->{sensor};
my $recipient = $config->{motion_gpg_public};

my $loop = IO::Async::Loop->new;
my $cass = Net::Async::CassandraCQL->new(
    host                => $cassandra_host,
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
    $gpg->encrypt(
        plaintext => $whole_path,
        output    => $output_whole_path,
        recipient => $recipient,
    );
    unlink($whole_path);
    my $upload_encrypted_file_statement = $cass->prepare(
    "INSERT INTO incidents (
        incident_id,
        facility,
        sensor,
        image,
        sensor_filename
    ) VALUES (
        now(),
        ?,
        ?,
        ?,
        ?
    );")->get;
    my $second_upload_encrypted_file_statement = $cass->prepare(
    "INSERT INTO incident_by_facility (
        incident_id,
        facility,
        sensor,
        image,
        sensor_filename
    ) VALUES (
        now(),
        ?,
        ?,
        ?,
        ?
    );")->get;
    my $encrypted_file_blob = undef;
    open(my $encrypted_filehandle, $output_whole_path) or die $!;
    read($encrypted_filehandle, $encrypted_file_blob, -s $encrypted_filehandle);
    my $x = $cass->execute($upload_encrypted_file_statement, [$facility, $sensor, $encrypted_file_blob, $output_filename])->get;
    $x = $cass->execute($second_upload_encrypted_file_statement, [$facility, $sensor, $encrypted_file_blob, $output_filename])->get;
}
