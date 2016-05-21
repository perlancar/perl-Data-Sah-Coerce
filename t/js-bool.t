#!perl

use 5.010001;
use strict;
use warnings;

use Data::Sah::CoerceJS qw(gen_coercer);
use Nodejs::Util qw(get_nodejs_path);
use Test::More 0.98;
use Test::Needs;

plan skip_all => 'node.js is not available' unless get_nodejs_path();

subtest "coerce_to=boolean" => sub {
    my $c = gen_coercer(type=>"bool");

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
        is_deeply($c->("foo"), "foo", "uncoerced");
        is_deeply($c->(2), 2, "uncoerced");
    };
    subtest "from str" => sub {
        is($c->("yes"), 1);
        is($c->("true"), 1);
        is($c->("on"), 1);
        is($c->("1"), 1);

        is($c->("no"), '');
        is($c->("false"), '');
        is($c->("off"), '');
        is($c->("0"), '');
    };
};

done_testing;
