package Log::Log4perl::Appender::Chunk::Store::Null;

use Moose;
extends qw/Log::Log4perl::Appender::Chunk::Store/;

sub store{}

__PACKAGE__->meta->make_immutable();
