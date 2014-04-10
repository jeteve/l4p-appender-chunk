package Log::Log4perl::Appender::Chunk::Store::S3;

use Moose;
extends qw/Log::Log4perl::Appender::Chunk::Store/;

use Net::Amazon::S3;
use Net::Amazon::S3::Client;

use Log::Log4perl;
my $LOGGER = Log::Log4perl->get_logger();

sub BEGIN{
    eval "require Net::Amazon::S3::Client;";
    if( $@ ){
        die "\n\nFor ".__PACKAGE__.": Cannot load Net::Amazon::S3::Client\n\n -> Please install that if you want to use S3 Log Chunk storage.\n\n";
    }
}

has 's3_client' => ( is => 'ro', isa => 'Net::Amazon::S3::Client', lazy_build => 1 );
has 'bucket' => ( is => 'ro' , isa => 'Net::Amazon::S3::Client::Bucket', lazy_build => 1);


has 'bucket_name' => ( is => 'ro' , isa => 'Str' , required => 1);
has 'aws_access_key_id' => ( is => 'ro' , isa => 'Str', required => 1 );
has 'aws_secret_access_key' => ( is => 'ro' , isa => 'Str' , required => 1);
has 'retry' => ( is => 'ro' , isa => 'Bool' , required => 1 , default => 1);

has 'vivify_bucket' => ( is => 'ro' , isa => 'Bool' , required => 1 , default => 0 );

sub _build_s3_client{
    my ($self) = @_;
    return Net::Amazon::S3::Client->new( s3 =>
                                         Net::Amazon::S3->new(
                                                              aws_access_key_id => $self->aws_access_key_id(),
                                                              aws_secret_access_key => $self->aws_secret_access_key(),
                                                              retry => $self->retry()
                                                             ));
}

=head2 clone

Returns a fresh copy of myself based on the same settings.

Usage:

 my $clone = $this->clone();

=cut

sub clone{
    my ($self) = @_;
    return __PACKAGE__->new({bucket_name => $self->bucket_name(),
                             aws_access_key_id => $self->aws_access_key_id(),
                             aws_secret_access_key => $self->aws_secret_access_key(),
                             retry => $self->retry(),
                             vivify_bucket => $self->vivify_bucket()
                            });
}

sub _build_bucket{
    my ($self) = @_;

    my $s3_client = $self->s3_client();
    my $bucket_name = $self->bucket_name();

    # Try to hit an existing bucket from the list
    my @buckets = $s3_client->buckets();
    foreach my $bucket ( @buckets ){
        if( $bucket->name() eq $bucket_name ){
            # Hit!
            return $bucket;
        }
    }

    unless( $self->vivify_bucket() ){
        confess("Could not find bucket ".$bucket_name." in this account [access_key_id='".$self->aws_access_key_id()."'] and no vivify_bucket option");
    }
    $LOGGER->info("Vivifying Amazon S3 bucket '".$bucket_name."' for S3 account [access_key_id='".$self->aws_access_key_id()."']");
    return $self->s3_client()->create_bucket( name => $bucket_name );
}

=head2 store

See superclass L<Log::Log4perl::Appender::Chunk::Store>

=cut

sub store{
    my ($self, $chunk_id, $big_message) = @_;

    my $s3object = $self->bucket()->object( key => $chunk_id );
    $s3object->put($big_message);
    return 1;
}

__PACKAGE__->meta->make_immutable();
