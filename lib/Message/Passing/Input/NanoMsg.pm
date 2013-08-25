package Message::Passing::Input::NanoMsg;
# ABSTRACT: input messages from nanomsg

use Moose;
use NanoMsg::Raw;
use MooseX::LazyRequire;
use namespace::autoclean;

with 'Message::Passing::Role::Input';

has protocol => (
    is            => 'ro',
    isa           => 'Str',
    lazy_required => 1,
);

has bind_address => (
    is            => 'ro',
    isa           => 'Str',
    lazy_required => 1,
);

has socket => (
    is      => 'ro',
    isa     => 'Int',
    builder => '_build_socket',
);

has subscribe => (
    traits  => ['Array'],
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    builder => '_build_subscribe',
    handles => {
        subscribe => 'elements',
    },
);

has watcher => (
    init_arg => undef,
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_watcher',
);

sub _build_socket {
    my ($self) = @_;

    my $sock = $self->_socket;
    $self->_bind($sock);
    $self->_subscribe($sock);
    $sock;
}

sub _socket {
    my ($self) = @_;

    my $sock = nn_socket(AF_SP, do {
        no strict 'refs';
        &{ 'NanoMsg::Raw::NN_' . $self->protocol }();
    });
    die nn_errno unless defined $sock;

    $sock;
}

sub _bind {
    my ($self, $sock) = @_;

    my $eid = nn_bind($sock, $self->bind_address);
    die nn_errno unless defined $sock;
}

sub _subscribe {
    my ($self, $sock) = @_;

    for my $s ($self->subscribe) {
        nn_setsockopt($sock, NN_SUB, NN_SUB_SUBSCRIBE, $s)
            or die nn_errno;
    }
}

sub _build_subscribe { [''] }

sub _build_watcher {
    my ($self) = @_;

    my $packed = nn_getsockopt($self->socket, NN_SOL_SOCKET, NN_RCVFD);
    die nn_errno unless defined $packed;

    my $rcvfd = unpack 'i', $packed;

    AE::io $rcvfd, 0, sub {
        # FIXME: circular ref
        $self->_recv;
    };
}

sub _recv {
    my ($self) = @_;

    my $ret = nn_recv($self->socket, my $buf);
    die nn_errno unless defined $ret;

    # It'd be kinda nice to be able to pass along the message buffer instance,
    # but many Message::Passing modules won't deal with it
    # nicely. Filter::Decoder::JSON, is an example of that.
    $self->output_to->consume(${ $buf });
}

sub BUILD {
    my ($self) = @_;

    $self->watcher;
}

__PACKAGE__->meta->make_immutable;

1;
