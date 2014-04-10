package Log::Log4perl::Appender::Chunk::Store;
use Moose;

sub store{
    my ($self, $chunk_id , $big_message) = @_;
    ...
}

__PACKAGE__->meta->make_immutable();
