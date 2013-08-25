package Message::Passing::Output::NanoMsg;

use Moose;
use NanoMsg::Raw;
use MooseX::LazyRequire;
use namespace::autoclean;

with 'Message::Passing::Role::Output';

has socket => (
    is      => 'ro',
    isa     => 'Int',
    builder => '_build_socket',
);

has protocol => (
    is            => 'ro',
    isa           => 'Str',
    lazy_required => 1,
);

has connect_address => (
    is            => 'ro',
    isa           => 'Str',
    lazy_required => 1,
);

sub _build_socket {
    my ($self) = @_;

    my $sock = $self->_socket;
    $self->_connect($sock);
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

sub _connect {
    my ($self, $sock) = @_;

    my $eid = nn_connect($sock, $self->connect_address);
    die nn_errno unless defined $eid;
}

sub consume {
    my ($self, $msg) = @_;

    my $ret = nn_send($self->socket, $msg);
    die nn_errno unless defined $ret;
}

__PACKAGE__->meta->make_immutable;

1;
