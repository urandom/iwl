use Test::More tests => 4;

use IWL::InputButton;

{
	my $button = IWL::InputButton->new;

	is($button->setLabel('My label'), $button);
	is($button->getLabel, 'My label');
	like($button->getContent, qr(^<input (?:(?:type="button"|class="inputbutton"|value="My label"|id="inputbutton_\d+")\s*){4}/>\n$));
}

{
	my $button = IWL::InputButton->new(submit => 1, id => 'foo');

	is_deeply($button->getObject, {
			tag => 'input',
			attributes => {
				type => 'submit',
				class => 'inputbutton',
				id => 'foo',
			}
	});
}
