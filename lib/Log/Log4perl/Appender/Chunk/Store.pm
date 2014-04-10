package Log::Log4perl::Appender::Chunk::Store;
use Moose;

sub store{
    my ($self, $chunk_id , $big_message) = @_;
    ...
}

__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

Log::Log4perl::Appender::Chunk::Store - Store adapter baseclass

=head1 DESCRIPTION

This is the baseclass for all Store adapters used by the
L<Log::Log4perl::Appender::Chunk> appender.

=head1 IMPLEMENTING YOUR OWN


=cut
