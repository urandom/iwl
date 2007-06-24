use Test::More tests => 5;

use IWL::Combo;

{
    my $combo = IWL::Combo->new;

    can_ok($combo->appendOption('Foo', 'bar'), 'setText');
    isa_ok($combo->prependOption('Alpha', 'beta'), 'IWL::Combo::Option');
}

{
    my $combo = IWL::Combo->new;

    is($combo->setMultiple(1), $combo);
    ok($combo->isMultiple);
    like($combo->getContent, qr(<select (?:(?:class="combo"|multiple)\s*){2}></select>));
}
