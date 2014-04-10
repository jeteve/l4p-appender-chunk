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

Make a subclass of this and implement the 'store' method.

Have a look at the minimalistic code in L<Log::Log4perl::Appender::Chunk::Store::Memory>.

=head2 store

This method will be called by the L<Log::Log4perl::Appender::Chunk> to store a whole chunk of log lines
under the given chunk ID.

Implement it in any subclass like:

  sub store{
     my ($self, $chunk_id, $chunk) = @_;
     ...
  }

=cut
