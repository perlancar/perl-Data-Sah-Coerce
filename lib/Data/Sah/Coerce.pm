package Data::Sah::Coerce;

# DATE
# VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::Any::IfLOG '$log';

use Exporter qw(import);
our @EXPORT_OK = qw(gen_coercer);

our %SPEC;

our $Log_Coercer_Code = $ENV{LOG_SAH_COERCER_CODE} // 0;

my $rule_modules_cache;
sub _list_rule_modules {
    return $rule_modules_cache if $rule_modules_cache;
    require PERLANCAR::Module::List;
    my $prefix = "Data::Sah::Coerce::perl::";
    my $mods = PERLANCAR::Module::List::list_modules(
        $prefix, {list_modules=>1, recurse=>1},
    );
    $rule_modules_cache = $mods;
    $mods;
}

$SPEC{gen_coercer} = {
    v => 1.1,
    summary => 'Generate coercer code',
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
        source => {
            summary => 'If set to true, will return coercer source code string'.
                ' instead of compiled code',
            schema => 'bool',
        },
    },
    result_naked => 1,
};
sub gen_coercer {
    my %args = @_;

    my $type = $args{type};

    my $all_mods = _list_rule_modules();

    my $typen = $type; $typen =~ s/::/__/g;
    my $prefix = "Data::Sah::Coerce::perl::$typen\::";
    my @rules;
    for my $mod (keys %$all_mods) {
        next unless $mod =~ /\A\Q$prefix\E(.+)/;
        push @rules, $1;
    }
    my %explicitly_included_rules;
    for my $rule (@{ $args{coerce_from} // [] }) {
        push @rules, $rule unless grep {$rule eq $_} @rules;
        $explicitly_included_rules{$rule}++;
    }
    if ($args{dont_coerce_from} && @{ $args{dont_coerce_from} }) {
        my @frules;
        for my $rule (@rules) {
            next if grep {$rule eq $_} @{ $args{dont_coerce_from} };
            push @frules, $rule;
        }
        @rules = @frules;
    }
    @rules = sort @rules;

    return sub { $_[0] } unless @rules;

    my @res;
    for my $rule (@rules) {
        my $mod = "$prefix$rule";
        my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
        require $mod_pm;
        next unless $explicitly_included_rules{$rule} ||
            &{"$mod\::meta"}->{enable_by_default};
        my $res = &{"$mod\::coerce"}(
            data_term => '$data',
            coerce_to => $args{coerce_to},
        );
        if ($res->{modules}) {
            for my $mod (keys %{$res->{modules}}) {
                my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
                require $mod_pm;
            }
        }
        push @res, $res;
    }
    last unless @rules;

    my $expr;
    for my $i (reverse 0..$#res) {
        my $res = $res[$i];
        if ($i == $#res) {
            $expr = "$res->{expr_match} ? $res->{expr_coerce} : \$data";
        } else {
            $expr = "$res->{expr_match} ? $res->{expr_coerce} : ($expr)";
        }
    }

    my $code = "sub { my \$data = shift; $expr }";
    if ($Log_Coercer_Code) {
        $log->tracef("Coercer code (gen args: %s): %s", \%args, $code);
    }

    return $code if $args{source};

    my $coercer = eval $code;
    die if $@;
    $coercer;
}

1;
# ABSTRACT: Coercion rules for Data::Sah

=head1 SYNOPSIS

 use Data::Sah::Coerce qw(gen_coercer);

 # a utility routine: gen_coercer
 my $c = gen_coercer(
     type               => 'date',
     coerce_to          => 'DateTime',
     # coerce_from      => [qw/str_alami/],   # explicitly enable some rules
     # dont_coerce_from => [qw/str_iso8601/], # explicitly disable some rules
 );

 my $val = $c->(123);          # unchanged, 123
 my $val = $c->(1463307881);   # becomes a DateTime object
 my $val = $c->("2016-05-15"); # becomes a DateTime object
 my $val = $c->("2016foo");    # unchanged, "2016foo"


=head1 DESCRIPTION

This distribution contains a standard set of coercion rules for L<Data::Sah>. It
is separated from the C<Data-Sah> distribution and can be used independently.

A coercion rule is put in
C<Data::Sah::Coerce::$LANG::$TARGET_TYPE::$SOURCE_TYPE_AND_EXTRA_DESCRIPTION>
module, for example: L<Data::Sah::Coerce::perl::date::int_epoch> for converting
date from integer (Unix epoch) or L<Data::Sah::Coerce::perl::date::str_iso8601>
for converting date from ISO8601 strings like "2016-05-15".

The module must contain C<meta> subroutine which must return a hashref that has
the following keys (C<*> marks that the key is required):

=over

=item * enable_by_default* => bool

Whether the rule should be used by default. Some rules might be useful in
certain situations only and can set this key's value to 0.

To explicitly enable a disabled-by-default rule, a Sah schema can specify an
attribute C<x.coerce_from> or C<x.perl.coerce_from>, etc to an array of coercion
rule names to enable explicitly (e.g. C<< ["int_epoch", "str_8601"] >>. On the
other hand, to explicitly disable an enabled-by-default rule, one can use the
C<x.dont_coerce_from> (or C<x.perl.dont_coerce_from>, etc).

=back

The module must also contain C<coerce> subroutine which must generate the code
for coercion. The subroutine must accept a hash of arguments (C<*> indicates
required arguments):

=over

=item * data_term => str

=item * coerce_to => str

Some Sah types are "abstract" and can be represented using a choice of several
actual types in the target programming language. For example, "date" can be
represented in Perl as an integer (Unix epoch value), or a DateTime object, or a
Time::Moment object.

Not all target Sah types will need this argument.

=back

The C<coerce> subroutine must return a hashref with the following keys (C<*>
indicates required keys):

=over

=item * expr_match => str

Expression in the target language to test whether the data can be coerced. For
example, in C<Data::Sah::Coerce::perl::date::int_epoch>, only integers ranging
from 10^8 to 2^31 are converted into date. Non-integers or integers outside this
range are not coerced.

=item * expr_coerce => str

Expression in the target language to actually convert data to the target type.

=item * modules => hash

A list of modules required by the expressions.

=back


=head1 VARIABLES

=head2 $Log_Coercer_Code => bool (default: from ENV or 0)

If set to true, will log the generated coercer code (currently using L<Log::Any>
at trace level). To see the log message, e.g. to the screen, you can use
something like:

 % TRACE=1 perl -MLog::Any::Adapter=Screen -MData::Sah::Coerce=gen_coercer \
     -E'my $c = gen_coercer(...)'


=head1 ENVIRONMENT

=head2 LOG_SAH_COERCER_CODE => bool

Set default for C<$Log_Coercer_Code>.


=head1 SEE ALSO

L<Data::Sah>
