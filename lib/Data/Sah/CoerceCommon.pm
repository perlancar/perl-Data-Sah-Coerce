package Data::Sah::CoerceCommon;

# DATE
# VERSION

use 5.010001;
use strict 'subs', 'vars';

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
specifically include a rule, or `!NAME` to exclude a rule, or `REGEX` or
`!REGEX` to include or exclude a pattern. All NAME's that contains a
non-alphanumeric, non-underscore character are assumed to be a REGEX pattern.

Without this setting, the default is to use all available coercion
rules that have `enabled_by_default` set to 1 in their metadata.

To use all rules (even those that are not enabled by default):

    ['.']

To not use any rules:

    ['!.']

To use only rules named R1 and R2 and not any other rules (even
enabled-by-default ones):

    ['!.', 'R1', 'R2']

To use only rules matching /^R/ and not any other rules (even
enabled-by-default ones):

    ['!.', '^R']

To use the default rules plus R1 and R2:

    ['R1', 'R2']

To use the default rules plus rules matching /^R/:

    ['^R']

To use the default rules but not R1 and R2:

    ['!R1', '!R2']

To use the default rules but not rules matching /^R/:

    ['!^R']

_
    },
);

my %gen_coercer_args = (
    %common_args,
    return_type => {
        schema => ['str*', in=>[qw/val str+val/]],
        default => 'val',
        description => <<'_',

`val` returns the value (possibly) coerced. `str+val` returns a 2-element array
where the first element is a bool value of whether the value has been coerced,
and the second element is the (possibly) coerced value.

_
    },
    source => {
        summary => 'If set to true, will return coercer source code string'.
            ' instead of compiled code',
        schema => 'bool',
    },
);

my %rule_modules_cache; # key=compiler, value=hash of {module=>undef}
sub _list_rule_modules {
    my $compiler = shift;
    return $rule_modules_cache{$compiler} if $rule_modules_cache{$compiler};
    require PERLANCAR::Module::List;
    my $prefix = "Data::Sah::Coerce::$compiler\::";
    my $mods = PERLANCAR::Module::List::list_modules(
        $prefix, {list_modules=>1, recurse=>1},
    );
    $rule_modules_cache{$compiler} = $mods;
    $mods;
}

our %SPEC;

$SPEC{get_coerce_rules} = {
    v => 1.1,
    summary => 'Get coerce rules',
    description => <<'_',

This routine lists coerce rule modules, filters out unwanted ones, loads the
rest, filters out old (version < current) modules or ones that are not enabled
by default. Finally the routine gets the rules out.

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

    my $all_mods = _list_rule_modules($compiler);

    my $typen = $type; $typen =~ s/::/__/g;
    my $prefix = "Data::Sah::Coerce::$compiler\::$typen\::";

    my @available_rule_names;
    for my $mod (keys %$all_mods) {
        next unless $mod =~ /\A\Q$prefix\E(.+)/;
        push @available_rule_names, $1;
    }

    my @used_rule_names = @available_rule_names;
    my %explicitly_used_rule_names;
    for my $item (@{ $args{coerce_rules} // [] }) {
        my $is_exclude = $item =~ s/\A!//;
        my $is_re;
        if ($item =~ /\A[A-Za-z0-9_]+\z/) {
            $is_re = 0;
        } else {
            $is_re = 1;
            eval { $item = qr/$item/ };
            die "Invalid regex in coerce_rules item '$item': $@" if $@;
        }
        if ($is_exclude) {
            if ($is_re) {
                # exclude rules matching pattern
                my @r;
                for my $r (@available_rule_names) {
                    next if $r =~ $item;
                    push @r, $r;
                }
                @used_rule_names = @r;
            } else {
                # exclude rules matching pattern
                my @r;
                for my $r (@available_rule_names) {
                    next if $r eq $item;
                    push @r, $r;
                }
                @used_rule_names = @r;
            }
        } else {
            if ($is_re) {
                # add rules matching pattern
                for my $r (@available_rule_names) {
                    next unless $r =~ $item;
                    $explicitly_used_rule_names{$r}++;
                    unless (grep { $_ eq $r } @used_rule_names) {
                        push @used_rule_names, $r;
                    }
                }
            } else {
                # add a specific rule
                die "Unknown coercion rule '$item', make sure the coercion ".
                    "rule module (Data::Sah::Coerce::$compiler\::$type\::$item".
                    " has been installed"
                    unless grep { $_ eq $item } @available_rule_names;
                push @used_rule_names, $item
                    unless grep { $_ eq $item } @used_rule_names;
                $explicitly_used_rule_names{$item}++;
            }
        }
    }

    my @rules;
    for my $rule_name (@used_rule_names) {
        my $mod = "$prefix$rule_name";
        my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
        require $mod_pm;
        my $rule_meta = &{"$mod\::meta"};
        my $rule_v = ($rule_meta->{v} // 1);
        if ($rule_v != 2) {
            warn "Coercion rule module '$mod' is still at ".
                "metadata version $rule_v, will not be used";
            next;
        }
        next unless $explicitly_used_rule_names{$rule_name} ||
            $rule_meta->{enable_by_default};
        my $rule = &{"$mod\::coerce"}(
            data_term => $dt,
            coerce_to => $args{coerce_to},
        );
        $rule->{name} = $rule_name;
        $rule->{meta} = $rule_meta;
        $rule->{explicitly_used} =
            $explicitly_used_rule_names{$rule_name} ? 1:0;
        push @rules, $rule;
    }

    # sort by priority (then name)
    @rules = sort {
        ($a->{meta}{prio}//50) <=> ($b->{meta}{prio}//50) ||
            $a cmp $b
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
                    warn "Coercion rule $rules[$j]{name} is precluded by rule $rule->{name}"
                        if $rule->{explicitly_used} && $rules[$j]{explicitly_used};
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
