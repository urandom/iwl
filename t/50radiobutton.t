use Test::More tests => 15;

use IWL::RadioButton;
use IWL::Stash;

{
    my $radio = IWL::RadioButton->new;

    is($radio->setLabel('My label'), $radio);
    is($radio->getLabel, 'My label');
	is($radio->setTitle('My title'), $radio);
	is($radio->getTitle, 'My title');

    is($radio->setChecked(1), $radio);
    ok($radio->isChecked);

    like($radio->getContent, qr(^<input (?:(?:checked="checked"|name="radiobutton_\d+"|class="radiobutton"|type="radio"|id="radiobutton_\d+"|title="My title")\s*){6}/>\n<label.*My title.*?>My label</label>\n$));
}

{
    my $radio = IWL::RadioButton->new;
    my $state = IWL::Stash->new;

    $radio->setChecked(1);
    is($radio->setName('radio'), $radio);
    is($radio->getName, 'radio');
    is($radio->setValue('bar'), $radio);
    is($radio->getValue, 'bar');

    ok($radio->extractState($state));
    is($state->getValues('radio'), 'bar');

    $state->setValues('radio', 'alpha');
    ok($radio->applyState($state));
	ok(!$radio->isChecked);
}
