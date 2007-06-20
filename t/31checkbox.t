use Test::More tests => 15;

use IWL::Checkbox;
use IWL::Stash;

{
    my $check = IWL::Checkbox->new;

    is($check->setLabel('My label'), $check);
    is($check->getLabel, 'My label');
	is($check->setTitle('My title'), $check);
	is($check->getTitle, 'My title');

    is($check->setChecked(1), $check);
    ok($check->getChecked);

    like($check->getContent, qr(^<input (?:(?:checked="checked"|name="checkbox_\d+"|class="checkbox"|type="checkbox"|id="checkbox_\d+"|title="My title")\s*){6}/>\n<label.*My title.*?>My label</label>\n$));
}

{
    my $check = IWL::Checkbox->new;
    my $state = IWL::Stash->new;

    $check->setChecked(1);
    is($check->setName('check'), $check);
    is($check->getName, 'check');
    is($check->setValue('bar'), $check);
    is($check->getValue, 'bar');

    ok($check->extractState($state));
    is($state->getValues('check'), 'bar');

    $state->setValues('check', 'alpha');
    ok($check->applyState($state));
    is($check->getValue, 'alpha');
}
