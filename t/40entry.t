use Test::More tests => 20;

use IWL::Entry;

use Locale::TextDomain qw(org.bloka.iwl);

my $entry = IWL::Entry->new;

{
	my $entry = IWL::Entry->new;

	is($entry->setPassword(1), $entry);
	is($entry->setReadonly(1), $entry);
	is($entry->setText('Some text'), $entry);
	is($entry->setDefaultText('Default text'), $entry);
	is($entry->setMaxLength(10), $entry);
	is($entry->setSize(3), $entry);

	ok($entry->isPassword);
	ok($entry->isReadonly);
	is($entry->getText, 'Some text');
	is($entry->getDefaultText, 'Default text');
	is($entry->getMaxLength, 10);
	is($entry->getSize, 3);

	like($entry->getContent, qr(^.*entry.js.*
<div (?:(?:class="entry password"|style="visibility: hidden"|id="(entry_\d+)")\s*){3}><input (?:(?:maxlength="10"|value="Some text"| size="3"|readonly="true"|class="entry_text entry_text_default"|type="password"|id="\1_text")\s*){7}/>\n</div>
<script.*IWL.Entry.create.*\1.*</script>\n)s);
}

{
	my $entry = IWL::Entry->new;

	is($entry->setIcon('foo.jpg')->setId('first_image'), $entry->{image1});
	is_deeply($entry->{image1}->getObject, {
			tag => 'img',
			attributes => {
				src => 'foo.jpg',
				id => 'first_image',
				class => 'entry_left'
			}
	});
	is($entry->setIconFromStock('IWL_STOCK_OK', 'right', 1)->setId('stock_image'), $entry->{image2});
	is_deeply($entry->{image2}->getObject, {
			tag => 'img',
			attributes => {
				alt => __('OK'),
				src => '/my/skin/darkness/tiny/ok.gif',
				id => 'stock_image',
				class => 'entry_right',
				style => {
					cursor => 'pointer'
				}
			}
	});
	is($entry->addClearButton, $entry);
	my $clear = __("Clear");
	like($entry->{image2}->getContent, qr(<img (?:(?:alt="$clear"|src="/my/skin/darkness/tiny/clear.gif"|class="entry_right"|class="entry_right"|id="entry_\d+_right"|style="cursor: pointer")\s*){5}/>\n)s);
}

{
	my $entry = IWL::Entry->new(id => 'foo');

	$entry->setAutoComplete('iwl_demo.pl');
	like($entry->getContent, qr(^<div (?:(?:class="entry"|style="visibility: hidden"|id="foo")\s*){3}><input (?:(?:class="entry_text"|id="foo_text"|type="text")\s*){3}/>\n<div (?:(?:class="entry_receiver"|id="foo_receiver")\s*){2}></div>\n</div>\n<script .*IWL.Entry.create.*foo.*</script>\n$)s);
}
