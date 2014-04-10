package Log::Log4perl::Appender::Chunk;
use Moose;

use Carp;
use Class::Load;
use Data::Dumper;
use Log::Log4perl::MDC;


# State variables:

# State can be:
# OFFCHUNK: No chunk is currently captured.
# INCHUNK: A chunk is currently captured in the buffer
# ENTERCHUNK: Entering a chunk from an OFFCHUNK state
# NEWCHUNK: Entering a NEW chunk from an INCHUNK state
# LEAVECHUNK: Leaving a chunk from an INCHUNK state
has 'state' => ( is => 'rw' , isa => 'Str', default => 'OFFCHUNK' );
has 'previous_chunk' => ( is => 'rw' , isa => 'Maybe[Str]' , default => undef , writer => '_set_previous_chunk' );
has 'messages_buffer' => ( is => 'rw' , isa => 'ArrayRef[Str]' , default => sub{ []; });

# Settings:
has 'chunk_marker' => ( is => 'ro' , isa => 'Str', required => 1, default => 'chunk' );

# Store:
has 'store' => ( is => 'ro', isa => 'Log::Log4perl::Appender::Chunk::Store',
                 required => 1, lazy_build => 1);
has 'store_class' => ( is => 'ro' , isa => 'Str' , default => 'Null' );
has 'store_args'  => ( is => 'ro' , isa => 'HashRef' , default => sub{ {}; });

has 'store_builder' => ( is => 'ro' , isa => 'CodeRef', required => 1, default => sub{
                             my ($self) = @_;
                             sub{
                                 $self->_full_store_class()->new($self->store_args());
                             }
                         });

sub _build_store{
    my ($self) = @_;
    return $self->store_builder()->();
}

sub _full_store_class{
    my ($self) = @_;
    my $full_class = $self->store_class();
    if( $full_class =~ /^\+/ ){
        $full_class =~ s/^\+//;
    }else{
        $full_class = 'Log::Log4perl::Appender::Chunk::Store::'.$full_class;
    }
    Class::Load::load_class($full_class);
    return $full_class;
}


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
    push @{$self->messages_buffer()} , $params->{message};
}

sub _on_INCHUNK{
    my ($self, $params) = @_;
    # Push the message in the buffer.
    push @{$self->messages_buffer()} , $params->{message};
}

sub _on_LEAVECHUNK{
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

    $self->store->store($chunk_id, $big_message);
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
            return 'LEAVECHUNK';
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