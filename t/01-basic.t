#!perl

use 5.010001;
use strict;
use warnings;

use Data::Sah::Coerce qw(gen_coercer);
use Test::More 0.98;

ok 1;
done_testing;
__END__
subtest "type:date" => sub {
    subtest "coerce_to=int(epoch)" => sub {
        my $c = gen_coercer(type=>"date", coerce_to=>"int(epoch)");
    };

        my $c1 = gen_coercer(type=>"date", coerce_to=>"DateTime");
        my $c1 = gen_coercer(type=>"date", coerce_to=>"Time::Moment");
        subtest "from:int_epoch" => sub {
        };

    subtest "from:str_iso8601" => sub {
        ok 1;
    };

    subtest "from:obj_DateTime" => sub {
        ok 1;
    };

    subtest "from:obj_TimeMoment" => sub {
        ok 1;
    };

};

# XXX test: opt:

done_testing;
