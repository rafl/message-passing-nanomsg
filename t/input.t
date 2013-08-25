use strict;
use warnings;
use Test::More 0.89;

use AnyEvent;
use NanoMsg::Raw;
use Message::Passing::Input::NanoMsg;
use Message::Passing::Filter::Decoder::JSON;
use Message::Passing::Output::Test;

my $cv = AE::cv;
my $output = Message::Passing::Output::Test->new({
    cb => sub { $cv->send },
});

my $dec = Message::Passing::Filter::Decoder::JSON->new({
    output_to => $output,
});

my $input = Message::Passing::Input::NanoMsg->new({
    protocol     => 'SUB',
    bind_address => 'inproc://test',
    output_to    => $dec,
});

my $sock = nn_socket(AF_SP, NN_PUB);
nn_connect($sock, 'inproc://test');
nn_send($sock, '{"message":"foo"}');

$cv->recv;

is $output->message_count, 1;
is_deeply [$output->messages], [{ message => 'foo' }];

done_testing;
