#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;
use Test::Needs;

use Data::Sah::Coerce;
use Data::Sah::CoerceCommon;
use Data::Sah::CoerceJS;

sub test_no_dupes {
    my $rules = shift;
    my %seen;
    for (@$rules) {
        if ($seen{$_->{name}}++) {
            ok 0, "Duplicate rule in rules: $_->{name}";
        }
    }
}

subtest "rule args" => sub {
    my $c_pl;

    $c_pl = Data::Sah::Coerce::gen_coercer(
        type=>"bool", return_type=>"bool_coerced+val",
        coerce_rules=>[["From_str::common_words", {ci=>1}]]);
    is_deeply($c_pl->("ON"), [1, 1]);
    is_deeply($c_pl->("on"), [1, 1]);

    $c_pl = Data::Sah::Coerce::gen_coercer(
        type=>"bool", return_type=>"bool_coerced+val",
        coerce_rules=>[["From_str::common_words", {ci=>0}]]);
    is_deeply($c_pl->("ON"), [1, "ON"]);
    is_deeply($c_pl->("on"), [1, 1]);
};

subtest "opt:coerce_rules" => sub {
    subtest "unknown name -> dies" => sub {
        dies_ok {
            Data::Sah::CoerceCommon::get_coerce_rules(
                compiler=>"perl", type=>"date", coerce_to=>'float(epoch)', data_term=>'$data',
                coerce_rules => ['From_str::FoO'],
            );
        };
    };
    subtest "unknown name in !name -> ignored" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"date", coerce_to=>'float(epoch)', data_term=>'$data',
            coerce_rules => ['!From_str::FoO'],
        );
        test_no_dupes($rules);
        ok(@$rules);
        ok(!(grep { $_->{name} eq 'FoO' } @$rules));
    };

    subtest "default (date)" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"date", coerce_to=>'float(epoch)', data_term=>'$data',
        );
        test_no_dupes($rules);
        ok(@$rules);
    };
    subtest "default (bool)" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"bool", data_term=>'$data',
        );
        test_no_dupes($rules);
        #ok(@$rules); # this dies happens to not include any enabled-by-default rule for bool
        ok(!(grep { $_->{name} eq 'str' } @$rules));
    };

    subtest "default + R" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"bool", data_term=>'$data',
            coerce_rules => ['From_str::common_words'],
        );
        test_no_dupes($rules);
        ok(@$rules);
        ok(grep { $_->{name} eq 'From_str::common_words' } @$rules);
    };

    subtest "default - R" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"date", coerce_to=>"float(epoch)", data_term=>'$data',
            coerce_rules=>['!From_float::epoch'],
        );
        test_no_dupes($rules);
        ok(@$rules);
        #diag explain $rules;
        ok(!grep { $_->{name} eq 'float_epoch' } @$rules);
    };
    subtest "default - R1 - R2" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"date", coerce_to=>"float(epoch)", data_term=>'$data',
            coerce_rules=>['!From_str::iso8601', '!From_obj::datetime'],
        );
        test_no_dupes($rules);
        ok(@$rules);
        #diag explain $rules;
        ok(!grep { $_->{name} eq 'From_str::iso8601' } @$rules);
        ok(!grep { $_->{name} eq 'From_obj::datetime' } @$rules);
    };
};

subtest "opt:return_type=bool_coerced+val" => sub {
    subtest "perl" => sub {
        test_needs "Time::Duration::Parse::AsHash";

        my $c_pl = Data::Sah::Coerce::gen_coercer(type=>"duration", coerce_to=>"float(secs)", return_type=>"bool_coerced+val");
        is_deeply($c_pl->("1h"), [1, 3600]);
        is_deeply($c_pl->("foo"), [undef, "foo"]);
    };

    subtest "js" => sub {
        my $c_js = Data::Sah::CoerceJS::gen_coercer(type=>"duration", coerce_to=>"float(secs)", return_type=>"bool_coerced+val");
        my $res;

        $res = $c_js->(3600);
        #diag explain $res;
        ok($res->[0]);
        is($res->[1], 3600);

        $res = $c_js->("foo");
        ok(!$res->[0]);
        is($res->[1], "foo");
    };
};

subtest "opt:return_type=bool_coerced+str_errmsg+val" => sub {
    subtest "perl" => sub {
        test_needs "DateTime";

        my $c_pl = Data::Sah::Coerce::gen_coercer(type=>"date", coerce_to=>"DateTime", return_type=>"bool_coerced+str_errmsg+val");
        my $res;

        $res = $c_pl->(1527889633);
        #diag explain $res;
        $res->[2] = $res->[2]->epoch;
        is_deeply($res, [1, undef, 1527889633]);

        $res = $c_pl->([]);
        is_deeply($res, [undef, undef, []]);

        $res = $c_pl->("2018-06-32");
        is($res->[0], 1);
        like($res->[1], qr/Invalid date/);
        is_deeply($res->[2], undef);
    };

    subtest "js" => sub {
        plan skip_all => "node.js not available" unless eval {
            require Nodejs::Util;
            Nodejs::Util::get_nodejs_path();
        };

        # JavaScript::QuickJS does not support Date object yet?
        my $c_js = Data::Sah::CoerceJS::gen_coercer(
            engine=>'nodejs',
            type=>"date", return_type=>"bool_coerced+str_errmsg+val");
        my $res;

        $res = $c_js->(1527889633);
        #diag explain $res;
        ok($res->[0]);
        ok(!$res->[1]);
        is($res->[2], "2018-06-01T21:47:13.000Z");

        $res = $c_js->([]);
        #diag explain $res;
        ok(!$res->[0]);
        ok(!$res->[1]);
        is_deeply($res->[2], []);

        $res = $c_js->("2018-06-32");
        #diag explain $res;
        ok($res->[0]);
        is($res->[1], "Invalid date");
        is_deeply($res->[2], undef);
    };
};

DONE_TESTING:
done_testing;
