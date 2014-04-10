package Log::Log4perl::Appender::Chunk::Store::S3;

use Moose;
extends qw/Log::Log4perl::Appender::Chunk::Store/;

use Net::Amazon::S3;
use Net::Amazon::S3::Client;

has 's3_client' => ( is => 'ro', isa => 'Net::Amazon::S3::Client', lazy_build => 1 );

has 'bucket_name' => ( is => 'ro' , isa => 'Str' , required => 1);
has 'aws_access_key_id' => ( is => 'ro' , isa => 'Str', required => 1 );
has 'aws_secret_access_key' => ( is => 'ro' , isa => 'Str' , required => 1);

has 's3config' => ( is => 'ro' , isa => 'HashRef', default => sub{ {}; });

has 'vivify_bucket' => ( is => 'ro' , isa => 'Bool' , required => 1 , default => 0 );

sub _build_s3_client{
    my ($self) = @_;
    return Net::Amazon::S3::Client->new( s3 =>
                                         Net::Amazon::S3->new(
                                                              aws_access_key_id => $self->aws_access_key_id(),
                                                              aws_secret_access_key => $self->aws_secret_access_key(),
                                                              %{$self->s3config()}
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
                             vivify_bucket => $self->vivify_bucket()
                            });
}

=head2 bucket

Returns a the L<Net::Amazon::S3::Client::Bucket>. Autovivify it
if the vivify_bucket is set to 1. Dies if something is wrong.

Usage:

  my $bucket = $this->bucket();

=cut

sub bucket{
    my ($self) = @_;

    my $bucket_name = $self->bucket_name();
    my $bucket = $self->s3_client()->bucket( name => $bucket_name );
    unless( $bucket ){
        if( $self->vivify_bucket() ){
            return $self->s3_client()->create_bucket( name => $bucket_name );
        }
        confess("No bucket $bucket_name in Amazon S3 account ".$self->aws_access_key_id());
    }
    return $bucket;
}

=head2 store

See superclass L<Log::Log4perl::Appender::Chunk::Store>

=cut

sub store{
    my ($self, $chunk_id, $big_message) = @_;

    my $s3object = $self->bucket()->object( key => $chunk_id );
    $s3object->put($big_message);
}

__PACKAGE__->meta->make_immutable();
