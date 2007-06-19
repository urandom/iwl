use Test::More tests => 5;

use IWL::Checkbox;

{
    my $check = IWL::Checkbox->new;

    is($check->setLabel('My label'), $check);
    is($check->getLabel, 'My label');

    is($check->setChecked(1), $check);
    ok($check->getChecked);

    like($check->getContent, qr(^<input (?:(?:checked="checked"|name="checkbox_\d+"|class="checkbox"|type="checkbox"|id="checkbox_\d+")\s*){5}/>\n<label.*?>My label</label>\n$));
}
