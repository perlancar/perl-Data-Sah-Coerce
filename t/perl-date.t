#!perl

use 5.010001;
use strict;
use warnings;

use Data::Sah::Coerce qw(gen_coercer);
use Test::More 0.98;
use Test::Needs;

subtest "coerce_to=int(epoch)" => sub {
    my $c = gen_coercer(type=>"date", coerce_to=>"int(epoch)");

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
        is_deeply($c->(1), 1);
    };
    subtest "from integer" => sub {
        is_deeply($c->(100_000_000), 100_000_000);
    };
    subtest "from DateTime object" => sub {
        test_needs "DateTime";
        is_deeply($c->(DateTime->new(year=>2016, month=>1, day=>1, time_zone=>"+0000")), 1451606400);
    };
    subtest "from Time::Moment object" => sub {
        test_needs "Time::Moment";
        is_deeply($c->(Time::Moment->new(year=>2016, month=>1, day=>1)), 1451606400);
    };
    subtest "from iso8601 string" => sub {
        test_needs "Time::Local";
        is_deeply($c->("2016-01-01T00:00:00Z"), 1451606400);
    };
};

subtest "coerce_to=DateTime" => sub {
    test_needs "DateTime";

    my $c = gen_coercer(type=>"date", coerce_to=>"DateTime");

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
        is_deeply($c->(1), 1);
    };
    subtest "from integer" => sub {
        my $d = $c->(100_000_000);
        is_deeply(ref($d), "DateTime");
        is_deeply("$d", "1973-03-03T09:46:40");
    };
    subtest "from DateTime object" => sub {
        my $d0 = DateTime->new(year=>2016, month=>1, day=>1, time_zone=>"Asia/Jakarta");
        my $d = $c->($d0);
        is_deeply(ref($d), "DateTime");
        is($d->epoch, $d0->epoch);
    };
    subtest "from Time::Moment object" => sub {
        test_needs "Time::Moment";
        my $d0 = Time::Moment->new(year=>2016, month=>1, day=>1);
        my $d = $c->($d0);
        is_deeply(ref($d), "DateTime");
        is($d->epoch, $d0->epoch);
    };
    subtest "from iso8601 string" => sub {
        test_needs "Time::Local";
        my $d = $c->("2016-01-01T00:00:00Z");
        is_deeply(ref($d), "DateTime");
        is($d->epoch, 1451606400);
    };
};

subtest "coerce_to=Time::Moment" => sub {
    test_needs "Time::Moment";

    my $c = gen_coercer(type=>"date", coerce_to=>"Time::Moment");

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
        is_deeply($c->(1), 1);
    };
    subtest "from integer" => sub {
        my $d = $c->(100_000_000);
        is_deeply(ref($d), "Time::Moment");
        is_deeply("$d", "1973-03-03T09:46:40Z");
    };
    subtest "from DateTime object" => sub {
        my $d0 = DateTime->new(year=>2016, month=>1, day=>1, time_zone=>"Asia/Jakarta");
        my $d = $c->($d0);
        is_deeply(ref($d), "Time::Moment");
        is($d->epoch, $d0->epoch);
    };
    subtest "from Time::Moment object" => sub {
        test_needs "Time::Moment";
        my $d0 = Time::Moment->new(year=>2016, month=>1, day=>1);
        my $d = $c->($d0);
        is_deeply(ref($d), "Time::Moment");
        is($d->epoch, $d0->epoch);
    };
    subtest "from iso8601 string" => sub {
        test_needs "Time::Local";
        my $d = $c->("2016-01-01T00:00:00Z");
        is_deeply(ref($d), "Time::Moment");
        is($d->epoch, 1451606400);
    };
};

done_testing;
