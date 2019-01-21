package Data::Sah::CoerceCommon;

# DATE
# VERSION

use 5.010001;
use strict 'subs', 'vars';

our %Default_Rules = (
    perl => {
        bool       => [qw//],
        date       => [qw/float_epoch obj_DateTime obj_TimeMoment str_iso8601/],
        datenotime => [qw/float_epoch obj_DateTime obj_TimeMoment str_iso8601/],
        datetime   => [qw/float_epoch obj_DateTime obj_TimeMoment str_iso8601/],
        duration   => [qw/float_secs obj_DateTimeDuration str_human str_iso8601/],
        timeofday  => [qw/obj_DateTimeOfDay str_hms/],
    },
    js => {
        bool       => [qw/float str/],
        date       => [qw/float_epoch obj_Date str/],
        datetime   => [qw/float_epoch obj_Date str/],
        datenotime => [qw/float_epoch obj_Date str/],
        duration   => [qw/float_secs str_iso8601/],
    },
);

my %common_args = (
    type => {
        schema => 'str*', # XXX sah::typename
            req => 1,
        pos => 0,
    },
    coerce_to => {
        schema => 'str*',
        description => <<'_',

Some Sah types, like `date`, can be represented in a choice of types in the
target language. For example, in Perl you can store it as a floating number
a.k.a. `float(epoch)`, or as a <pm:DateTime> object, or <pm:Time::Moment>
object. Storing in DateTime can be convenient for date manipulation but requires
an overhead of loading the module and storing in a bulky format. The choice is
yours to make, via this setting.

_
    },
    coerce_rules => {
        summary => 'A specification of coercion rules to use (or avoid)',
        schema => ['array*', of=>'str*'],
        description => <<'_',

This setting is used to specify which coercion rules to use (or avoid) in a
flexible way. Each element is a string, in the form of either `NAME` to mean
specifically include a rule, or `!NAME` to exclude a rule.

Some coercion modules are used by default, unless explicitly avoided using the
'!NAME' rule.

To not use any rules:

To use the default rules plus R1 and R2:

    ['R1', 'R2']

To use the default rules but not R1 and R2:

    ['!R1', '!R2']

_
    },
);

my %gen_coercer_args = (
    %common_args,
    return_type => {
        schema => ['str*', in=>[qw/val status+val status+err+val/]],
        default => 'val',
        description => <<'_',

`val` means the coercer will return the input (possibly) coerced or undef if
coercion fails.

`status+val` means the coercer will return a 2-element array. The first element
is a bool value set to 1 if coercion has been performed or 0 if otherwise. The
second element is the (possibly) coerced input (or undef if there is a failure
during coercion).

`status+err+val` means the coercer will return a 3-element array. The first
element is a bool value set to 1 if coercion has been performed or 0 if
otherwise. The second element is the error message string which will be set if
there is a failure in coercion. The third element is the (possibly) coerced
input (or undef if there is a failure during coercion).

_
    },
    source => {
        summary => 'If set to true, will return coercer source code string'.
            ' instead of compiled code',
        schema => 'bool',
    },
);

our %SPEC;

$SPEC{get_coerce_rules} = {
    v => 1.1,
    summary => 'Get coerce rules',
    description => <<'_',

This routine determines coerce rule modules to use (based on the default set and
`coerce_rules` specified), loads them, filters out modules with old/incompatible
metadata version, and return the list of rules.

This common routine is used by <pm:Data::Sah> compilers, as well as
<pm:Data::Sah::Coerce> and <pm:Data::Sah::CoerceJS>.

_
    args => {
        %common_args,
        compiler => {
            schema => 'str*',
            req => 1,
        },
        data_term => {
            schema => 'str*',
            req => 1,
        },
    },
};
sub get_coerce_rules {
    my %args = @_;

    my $type     = $args{type};
    my $compiler = $args{compiler};
    my $dt       = $args{data_term};

    my $typen = $type; $typen =~ s/::/__/g;
    my $prefix = "Data::Sah::Coerce::$compiler\::$typen\::";

    my @rule_names = @{ $Default_Rules{$compiler}{$typen} || [] };
    for my $item (@{ $args{coerce_rules} // [] }) {
        my $is_exclude = $item =~ s/\A!//;
        $item =~ /\A[A-Za-z0-9_]+\z/
            or die "Invalid coercion rule item '$item', please only use ".
            "alphanumeric characters";
        if ($is_exclude) {
            @rule_names = grep { $_ ne $item } @rule_names;
        } else {
            push @rule_names, $item unless grep { $_ eq $item } @rule_names;
        }
    }

    my @rules;
    for my $rule_name (@rule_names) {
        my $mod = "$prefix$rule_name";
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;
        my $rule_meta = &{"$mod\::meta"};
        my $rule_v = ($rule_meta->{v} // 1);
        if ($rule_v != 3 && $rule_v != 4) {
            warn "Only coercion rule module following metadata version 3/4 is ".
                "supported, this rule module '$mod' follows metadata version ".
                "$rule_v and will not be used";
            next;
        }
        my $rule = &{"$mod\::coerce"}(
            data_term => $dt,
            coerce_to => $args{coerce_to},
        );
        $rule->{name} = $rule_name;
        $rule->{meta} = $rule_meta;
        push @rules, $rule;
    }

    # sort by priority (then name)
    @rules = sort {
        ($a->{meta}{prio}//50) <=> ($b->{meta}{prio}//50) ||
            $a->{name} cmp $b->{name}
        } @rules;

    # precludes
    {
        my $i = 0;
        while ($i < @rules) {
            my $rule = $rules[$i];
            if ($rule->{meta}{precludes}) {
                for my $j (reverse 0 .. $#rules) {
                    next if $j == $i;
                    my $match;
                    for my $p (@{ $rule->{meta}{precludes} }) {
                        if (ref($p) eq 'Regexp' && $rules[$j]{name} =~ $p ||
                                $rules[$j]{name} eq $p) {
                            $match = 1;
                            last;
                        }
                    }
                    next unless $match;
                    warn "Coercion rule $rules[$j]{name} is precluded by rule $rule->{name}";
                    splice @rules, $j, 1;
                }
            }
            $i++;
        }
    }

    \@rules;
}

1;
# ABSTRACT: Common stuffs for Data::Sah::Coerce and Data::Sah::CoerceJS
