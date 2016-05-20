#!perl

use 5.010001;
use strict;
use warnings;

use Data::Sah::Coerce;
use Data::Sah::CoerceJS;
use Test::More 0.98;

# XXX test opt:coerce_from
# XXX test opt:coerce_from unknown module
# XXX test opt:dont_coerce_from
# XXX test opt:done_coerce_from unknown module

subtest "opt:return_type=bool+val" => sub {
    my $c_pl = Data::Sah::Coerce::gen_coercer(type=>"duration", coerce_to=>"float(secs)", return_type=>"bool+val");
    is_deeply($c_pl->("1h"), [1, 3600]);
    is_deeply($c_pl->("foo"), [0, "foo"]);

    my $c_js = Data::Sah::CoerceJS::gen_coercer(type=>"duration", coerce_to=>"float(secs)", return_type=>"bool+val");
    my $res;
    $res = $c_js->(3600);
    ok($res->[0]);
    is($res->[1], 3600);
    $res = $c_js->("foo");
    ok(!$res->[0]);
    is($res->[1], "foo");
};

ok 1;
done_testing;
