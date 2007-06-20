use Test::More tests => 4;

use IWL::Combo;

{
    my $combo = IWL::Combo->new;

    can_ok($combo->appendOption('Foo', 'bar'), 'setText');
}

{
    my $combo = IWL::Combo->new;

    is($combo->setMultiple(1), $combo);
    ok($combo->hasAttribute('multiple'));
    like($combo->getContent, qr(<select (?:(?:class="combo"|multiple)\s*){2}></select>));
}
