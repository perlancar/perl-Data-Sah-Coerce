#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Needs;

use Data::Sah::Coerce qw(gen_coercer);

# some tests are "covered" by perl-date.t

subtest "coerce_to=float(epoch)" => sub {
    my $c = gen_coercer(type=>"datetime", coerce_to=>"float(epoch)");

    subtest "from iso8601 string" => sub {
        test_needs "Time::Local";
        like($c->("2016-01-01T00:00:00Z"), qr/\A\d+\z/); # coerced
        is($c->("2016-01-01"), "2016-01-01"); # uncoerced
    };
};

done_testing;
