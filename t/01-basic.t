#!perl

use 5.010001;
use strict;
use warnings;

use Data::Sah::Coerce;
use Data::Sah::CoerceJS;
use Nodejs::Util qw(get_nodejs_path);
use Test::More 0.98;

# XXX test opt:coerce_from
# XXX test opt:coerce_from unknown module
# XXX test opt:dont_coerce_from
# XXX test opt:done_coerce_from unknown module

subtest "opt:return_type=sah+val" => sub {
    subtest "perl" => sub {
        my $c_pl = Data::Sah::Coerce::gen_coercer(type=>"duration", coerce_to=>"float(secs)", return_type=>"str+val");
        is_deeply($c_pl->("1h"), ["str_human", 3600]);
        is_deeply($c_pl->("foo"), [undef, "foo"]);
    };

    subtest "js" => sub {
        plan skip_all => "node.js not available" unless get_nodejs_path();

        my $c_js = Data::Sah::CoerceJS::gen_coercer(type=>"duration", coerce_to=>"float(secs)", return_type=>"str+val");
        my $res;
        is_deeply($c_js->(3600), ["float_secs", 3600]);
        is_deeply($c_js->("foo"), [undef, "foo"]);
    };
};

ok 1;
done_testing;
