#!/bin/false

package Foo;

use strict;

sub new {bless {prop1 => 42, prop2 => Bar->new}, shift}
sub printJS {
    return "Hello JS.";
}
sub overloaded {
    return 1 if (caller(1))[0] eq 'IWL::P2J';
    return 0;
}
sub this {
    return shift;
}

package Bar;

sub new {bless [am => 'bar'], shift}

1;
