package Data::Sah::Coerce;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use Data::Sah::CoerceCommon;

use Exporter qw(import);
our @EXPORT_OK = qw(gen_coercer);

our %SPEC;

our $Log_Coercer_Code = $ENV{LOG_SAH_COERCER_CODE} // 0;

$SPEC{gen_coercer} = {
    v => 1.1,
    summary => 'Generate coercer code',
    description => <<'_',

This is mostly for testing. Normally the coercion rules will be used from
`Data::Sah`.

_
    args => {
        %Data::Sah::CoerceCommon::gen_coercer_args,
    },
    result_naked => 1,
};
sub gen_coercer {
    my %args = @_;

    my $rt = $args{return_type} // 'val';
    my $rt_sv = $rt eq 'str+val';

    my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
        %args,
        compiler=>'perl',
        data_term=>'$data',
    );

    my $code;
    if (@$rules) {
        # load all the required perl modules
        for my $rule (@$rules) {
            next unless $rule->{modules};
            for my $mod (keys %{$rule->{modules}}) {
                my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
                require $mod_pm;
            }
        }

        my $expr;
        for my $i (reverse 0..$#{$rules}) {
            my $rule = $rules->[$i];
            if ($i == $#{$rules}) {
                if ($rt_sv) {
                    $expr = "($rule->{expr_match}) ? ['$rule->{name}', $rule->{expr_coerce}] : [undef, \$data]";
                } else {
                    $expr = "($rule->{expr_match}) ? ($rule->{expr_coerce}) : \$data";
                }
            } else {
                if ($rt_sv) {
                    $expr = "($rule->{expr_match}) ? ['$rule->{rule}', $rule->{expr_coerce}] : ($expr)";
                } else {
                    $expr = "($rule->{expr_match}) ? ($rule->{expr_coerce}) : ($expr)";
                }
            }
        }

        $code = join(
            "",
            "sub {\n",
            "    my \$data = shift;\n",
            ($rt_sv ?
                 "    return [undef, undef] unless defined(\$data);\n" :
                 "    return undef unless defined(\$data);\n"
             ),
            "    $expr;\n",
            "}",
        );
    } else {
        if ($rt_sv) {
            $code = 'sub { [undef, $_[0]] }';
        } else {
            $code = 'sub { $_[0] }';
        }
    }

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
     # return_type      => 'str+val',         # default is 'val'
 );

 my $val = $c->(123);          # unchanged, 123
 my $val = $c->(1463307881);   # becomes a DateTime object
 my $val = $c->("2016-05-15"); # becomes a DateTime object
 my $val = $c->("2016foo");    # unchanged, "2016foo"


=head1 DESCRIPTION

This distribution contains a standard set of coercion rules for L<Data::Sah>. It
is separated from the C<Data-Sah> distribution and can be used independently.

A coercion rule is put in
C<Data::Sah::Coerce::$COMPILER::$TARGET_TYPE::$SOURCE_TYPE_AND_EXTRA_DESCRIPTION>
module, for example: L<Data::Sah::Coerce::perl::date::float_epoch> for
converting date from integer (Unix epoch) or
L<Data::Sah::Coerce::perl::date::str_iso8601> for converting date from ISO8601
strings like "2016-05-15".

The module must contain C<meta> subroutine which must return a hashref that has
the following keys (C<*> marks that the key is required):

=over

=item * v* => int (default: 1)

Metadata specification version. Currently at 1.

=item * enable_by_default* => bool

Whether the rule should be used by default. Some rules might be useful in
certain situations only and can set this key's value to 0.

To explicitly enable a disabled-by-default rule, a Sah schema can specify an
attribute C<x.coerce_from> or C<x.perl.coerce_from>, etc to an array of coercion
rule names to enable explicitly (e.g. C<< ["float_epoch", "str_8601"] >>. On the
other hand, to explicitly disable an enabled-by-default rule, one can use the
C<x.dont_coerce_from> (or C<x.perl.dont_coerce_from>, etc).

=item * might_die => bool (default: 0)

Whether the rule will generate code that might die (e.g. does not trap failure
in a conversion process). An example of a rule like this is coercing from string
in the form of "YYYY-MM-DD" to a DateTime object. The rule might match any
string in the form of C<< /\A(\d{4})-(\d{2})-(\d{2})\z/ >> and feed it to C<<
DateTime->new >>, without checking of a valid date, so the latter might die.

An example of rule that "might not die" is coercing from a comma-separated
string into array. This process should not die unless under extraordinary
condition (e.g. out of memory).

For a rule that might die, the program/library that uses the rule module might
add an eval block around the expr_coerce code that is generated by the rule
module.

=item * prio => int (0-100, default: 50)

This is to regulate the ordering of rules. The higher the number, the lower the
priority (meaning the rule will be put further back). Rules that are
computationally expensive and/or matches more broadly in general should be put
further back (lower priority, higher number).

=item * precludes => array of (str|re)

List the other rules or rule patterns that are precluded by this rule. Rules
that are pure alternatives to one another (e.g. date coercien rules
L<str_alami|Data::Sah::Coerce::date::str_alami> vs
L<str_alami|Data::Sah::Coerce::date::str_alami> both parse natural language date
string; there is little to none usefulness in using both; besides, both rules
match all string and dies when failing to parse the string. So in C<str_natural>
rule, you might find this metadata:

 precludes => [qr/\Astr_alami(_.+)?\z/]

and in C<str_alami> rule you might find this metadata:

 precludes => [qr/\Astr_alami(_.+)?\z/, 'str_natural']

Note that the C<str_alami> rule also precludes other C<str_alami_*> rules (like
C<str_alami_en> and C<str_alami_id>).

Also note that rules which are specifically requested to be used (e.g. using
C<x.perl.coerce_from> attribute in Sah schema) are not precluded by other rules'
C<precludes> metadata.

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
example, in C<Data::Sah::Coerce::perl::date::float_epoch>, only integers ranging
from 10^8 to 2^31 are converted into date. Non-integers or integers outside this
range are not coerced.

=item * expr_coerce => str

Expression in the target language to actually convert data to the target type.

=item * modules => hash

A list of modules required by the expressions.

=back

Basically, the C<coerce> subroutine must generates a code that accepts a
non-undef data and must convert this data to the desired type/format under the
right condition. The code to match the right condition must be put in
C<expr_match> and the code to convert data must be put in C<expr_coerce>.

Program/library that uses Data::Sah::Coerce can collect rules from the rule
modules then compose them into the final code, something like (in pseudocode):

 if (data is undef) {
   return undef;
 } elsif (data matches expr-match-from-rule1) {
   return expr-coerce-from-rule1;
 } elsif (data matches expr-match-from-rule2) {
   return expr-coerce-from-rule1;
 ...
 } else {
   # does not match any expr-match
   return original data;
 }


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

L<Data::Sah::CoerceJS>
