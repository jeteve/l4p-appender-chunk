use strict;
use warnings;
package Log::Log4perl::Appender::Chunk;

use Data::Dumper;

sub new{
    my ($class, %options) = @_;

    my $self = {
                messages_buffer => [],
                %options
               };
    bless $self, $class;
    return $self;
}

sub log{
    my ($self, %params) = @_;
    warn Dumper(\%params);
}

1;

__END__

=head1 NAME

Log::Log4perl::Appender::Chunk - Group log messages in chunks

=cut
