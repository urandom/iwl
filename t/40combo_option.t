use Test::More tests => 11;

use IWL::Combo::Option;

my $option = IWL::Combo::Option->new;

is($option->getText, '');
is($option->setText('Foo bar'), $option);
is($option->getText, 'Foo bar');
is($option->setSelected(1), $option);
ok($option->isSelected);
is($option->setSelected, $option);
ok(!$option->isSelected);
is($option->setValue('alpha'), $option);
is($option->getValue, 'alpha');
is($option->getContent, '<option value="alpha">Foo bar</option>' . "\n");
is_deeply($option->getObject, {
        tag => 'option',
        children => [{ text => 'Foo bar' }],
        attributes => { value => 'alpha' }
});
