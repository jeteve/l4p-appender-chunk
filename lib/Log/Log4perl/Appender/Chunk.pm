package Log::Log4perl::Appender::Chunk;
use Moose;

use Carp;
use Data::Dumper;
use Log::Log4perl::MDC;

# State variables:
has 'state' => ( is => 'rw' , isa => 'Str', default => 'OFFCHUNK' );
has 'previous_chunk' => ( is => 'rw' , isa => 'Maybe[Str]' , default => undef , writer => '_set_previous_chunk' );
has 'messages_buffer' => ( is => 'rw' , isa => 'ArrayRef[Str]' , default => sub{ []; });

# Settings:
has 'chunk_marker' => ( is => 'ro' , isa => 'Str', required => 1, default => 'chunk' );


# sub new{
#     my ($class, %options) = @_;

#     my $self = {
#                 state => 'OFFCHUNK',
#                 previous_chunk => undef,
#                 messages_buffer => [],
#                 chunk_marker => 'chunk',
#                 store_class => 'Memory',
#                 store_args => {},
#                 %options
#                };
#     warn Dumper($self);
#     bless $self, $class;
#     return $self;
# }

sub log{
    my ($self, %params) = @_;

    my $chunk = Log::Log4perl::MDC->get($self->chunk_marker());

    # warn "CHUNK: $chunk";
    # warn Dumper(\%params);

    # Change the state according to the chunk param
    $self->{state} = $self->_compute_state($chunk);

    # Act according to the state
    my $m_name = '_on_'.$self->state();

    $self->$m_name(\%params);

    $self->_set_previous_chunk($chunk);
}

sub _on_OFFCHUNK{
    my ($self, $params) = @_;
    # Chunk is Off, nothing much to do.
}

sub _on_ENTERCHUNK{
    my ($self,$params) = @_;
    # Push the message in the buffer.
    push @{$self->{messages_buffer}} , $params->{message};
}

sub _on_INCHUNK{
    my ($self, $params) = @_;
    # Push the message in the buffer.
    push @{$self->{messages_buffer}} , $params->{message};
}

sub _on_OUTCHUNK{
    my ($self, $params) = @_;
    # The new message should not be pushed on the buffer.

    # Flush the buffer in one big message.
    my $big_message = join('',@{$self->{messages_buffer}});
    $self->{messages_buffer} = [];

    # The chunk ID is in the previous chunk. This should NEVER be null
    my $chunk_id = $self->{previous_chunk};
    unless( defined $chunk_id ){
        confess("Undefined previous chunk. This should never happen");
    }

    warn "WILL EMIT as chunk_id=$chunk_id: $big_message";
}

sub _compute_state{
    my ($self, $chunk) = @_;
    my $previous_chunk = $self->{previous_chunk};

    if( defined $chunk ){
        if( defined $previous_chunk ){
            if( $previous_chunk eq $chunk ){
                # State  is INCHUNK
                return 'INCHUNK';
            }else{
                # Chunks are different
                return 'NEWCHUNK';
            }
        }else{
            # No previous chunk.
            return 'ENTERCHUNK';
        }
    }else{
        # No chunk defined.
        if( defined $previous_chunk ){ # But a previous chunk
            return 'OUTCHUNK';
        }else{
            # No previous chunk neither
            return 'OFFCHUNK';
        }
    }

    confess("UNKNOWN CASE. This should never be reached.");
}

__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

Log::Log4perl::Appender::Chunk - Group log messages in chunks

=cut
