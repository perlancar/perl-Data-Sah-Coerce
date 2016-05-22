package Data::Sah::CoerceCommon;

# DATE
# VERSION

use 5.010001;
use strict 'subs', 'vars';

my $sch_array_of_str_or_re = ['array*', of=>['any*',of=>['str*','re*']]];

my %common_args = (
    type => {
        schema => 'str*', # XXX sah::typename
            req => 1,
        pos => 0,
    },
    coerce_to => {
        schema => 'str*',
    },
    coerce_from => {
        schema => $sch_array_of_str_or_re,
    },
    dont_coerce_from => {
        schema => $sch_array_of_str_or_re,
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

This common routine is used by `Data::Sah` compilers, as well as
`Data::Sah::Coerce` and `Data::Sah::CoerceJS`.

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

    my @rule_names;
    for my $mod (keys %$all_mods) {
        next unless $mod =~ /\A\Q$prefix\E(.+)/;
        push @rule_names, $1;
    }
    my %explicitly_included_rule_names;
    for my $rule_name (@{ $args{coerce_from} // [] }) {
        push @rule_names, $rule_name unless grep {$rule_name eq $_} @rule_names;
        $explicitly_included_rule_names{$rule_name}++;
    }
    if ($args{dont_coerce_from} && @{ $args{dont_coerce_from} }) {
        my @frule_names;
        for my $rule_name (@rule_names) {
            next if grep {$rule_name eq $_} @{ $args{dont_coerce_from} };
            push @frule_names, $rule_name;
        }
        @rule_names = @frule_names;
    }

    my @rules;
    for my $rule_name (@rule_names) {
        my $mod = "$prefix$rule_name";
        my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
        require $mod_pm;
        my $rule_meta = &{"$mod\::meta"};
        my $rule_v = ($rule_meta->{v} // 1);
        if ($rule_v != 2) {
            warn "Coercion rule module '$mod' is still at ".
                "version $rule_v, will not be used";
            next;
        }
        next unless $explicitly_included_rule_names{$rule_name} ||
            $rule_meta->{enable_by_default};
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
            $a cmp $b
        } @rules;

    \@rules;
}

1;
# ABSTRACT: Common stuffs for Data::Sah::Coerce and Data::Sah::CoerceJS
