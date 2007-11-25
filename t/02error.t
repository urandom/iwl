package main;

use Test::More tests => 27;

my $t = ErrorTest->new;

ok(!$t->fillError('foo'));
ok(!$t->bad);
is(1, $t->errors);
ok(!$t->fillError(qw(bar baz)));
ok(!$t->bad);
is(3, $t->errors);
ok(!$t->fillBadError('alpha'));
ok($t->bad);
is(4, $t->errors);
ok(!$t->fillBadError(qw(tango foxtrot)));
ok($t->bad);
is(6, $t->errors);
is_deeply(
    [qw(foo bar baz alpha tango foxtrot)],
    [$t->errorList]
);
is(6, $t->errors);
is_deeply(
    [qw(foo bar baz alpha tango foxtrot)],
    [$t->errorShift]
);
ok(!$t->bad);
is(0, $t->errors);
ok(!$t->fillError('foo'));
is(1, $t->errors);
is_deeply(['foo'], [$t->errorSuck]);
is(0, $t->errors);
ok(!$t->fillError("foo\n"));
is_deeply(["foo\n"], [$t->errorList]);
is($t, $t->chompErrors);
is_deeply(["foo"], [$t->errorList]);
is($t->clearErrors, $t);
is($t->errors, 0);

package ErrorTest;

use base 'IWL::Error';

sub new {
    return bless {}, shift;
}

sub fillError {
    shift->_pushError(@_);
}

sub fillBadError {
    shift->_pushFatalError(@_);
}
