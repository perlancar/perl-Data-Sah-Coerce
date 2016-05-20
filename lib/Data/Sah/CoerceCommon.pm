package Data::Sah::CoerceCommon;

# DATE
# VERSION

our $gen_coercer_meta = {
    v => 1.1,
    summary => 'Generate coercer code',
    description => <<'_',

This is mostly for testing. Normally the coercion rules will be used from
`Data::Sah`.

_
    args => {
        type => {
            schema => 'str*', # XXX sah::typename
            req => 1,
            pos => 0,
        },
        coerce_to => {
            schema => 'str*',
        },
        coerce_from => {
            schema => ['array*', of=>'str*'],
        },
        dont_coerce_from => {
            schema => ['array*', of=>'str*'],
        },
        return_type => {
            schema => ['str*', in=>[qw/val bool+val/]],
            default => 'val',
            description => <<'_',

`val` returns the value (possibly) coerced. `bool+val` returns a 2-element array
where the first element is a bool value of whether the value has been coerced,
and the second element is the (possibly) coerced value.

_
        },
        source => {
            summary => 'If set to true, will return coercer source code string'.
                ' instead of compiled code',
            schema => 'bool',
        },
    },
    result_naked => 1,
};

1;
# ABSTRACT: Common stuffs for Data::Sah::Coerce and Data::Sah::CoerceJS
