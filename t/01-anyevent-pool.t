# Copyright (C) 2015 Yoann Le Garff, Nicolas Boquet and Yann Le Bras
# navel-anyevent-pool is licensed under the Apache License, Version 2.0

#-> BEGIN

#-> initialization

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

use AnyEvent;

BEGIN {
    use_ok('Navel::AnyEvent::Pool');
}

#-> main

my $count = 0;
my $after = 2;

my $done = AnyEvent->condvar();

my $pool;

lives_ok {
    $pool = Navel::AnyEvent::Pool->new();
} 'create pool';

lives_ok {
    alarm $after + 1;

    $pool->attach_timer(
        name => 'begin',
        after => 1,
        interval => 1,
        callback => sub {
            $count++;
        }
    );

    $pool->attach_timer(
        name => 'end',
        after => $after,
        callback => sub {
            $done->send();
        }
    );
} 'attach timers';

$done->recv();

ok($count == $after, 'events properly planned');

#-> END

__END__
