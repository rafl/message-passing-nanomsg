use strict;
use warnings;
use Test::More 0.89;

use AE;
use JSON 'encode_json';
use Message::Passing::Input::NanoMsg;
use Message::Passing::Output::NanoMsg;
use Message::Passing::Output::Test;
use Message::Passing::Filter::Decoder::JSON;

my $output = Message::Passing::Output::NanoMsg->new({
    protocol        => 'PUB',
    connect_address => 'inproc://test',
});

my $cv = AE::cv;
my $input = Message::Passing::Input::NanoMsg->new({
    protocol     => 'SUB',
    bind_address => 'inproc://test',
    output_to    => Message::Passing::Filter::Decoder::JSON->new({
        output_to => Message::Passing::Output::Test->new({
            cb => sub { $cv->send },
        }),
    }),
});

$output->consume(encode_json { foo => 'bar' });
$cv->recv;

is $input->output_to->output_to->message_count, 1;
is_deeply([$input->output_to->output_to->messages], [{foo => 'bar'}]);

done_testing;
