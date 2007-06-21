use Test::More tests => 12;

use IWL::Textarea;
use IWL::Stash;

{
	my $area = IWL::Textarea->new;

	is($area->setReadonly(1), $area);
	ok($area->isReadonly);
	is($area->setText('My text'), $area);
	is($area->getText, 'My text');
	like($area->getContent, qr(^<textarea (?:(?:readonly="true"|class="textarea")\s*){2}>My text</textarea>\n$));
}

{
	my $area = IWL::Textarea->new;
	my $state = IWL::Stash->new;

	is($area->setName('foo'), $area);
	is($area->setText('My stashed text'), $area);
	ok($area->extractState($state));
	is($state->getValues('foo'), 'My stashed text');
	ok($state->setValues('foo', 'Some other text'));
	ok($area->applyState($state));
	is($area->getText, 'Some other text');
}
