use Test::More tests => 12;

use IWL::Entry;

use Locale::TextDomain qw(org.bloka.iwl);

my $entry = IWL::Entry->new;

{
	my $entry = IWL::Entry->new;

	is($entry->setPassword(1), $entry);
	is($entry->setReadonly(1), $entry);
	is($entry->setText('Some text'), $entry);
	is($entry->setMaxLength(10), $entry);
	is($entry->setSize(3), $entry);
	like($entry->getContent, qr(<span (?:(?:class="entry password"|id="entry_\d+")\s*){2}><input (?:(?:maxlength="10"|readonly="true"|value="Some text"|class="entry_text"|id="entry_\d+_text"|type="password"|size="3")\s*){7}/>\n</span>\n));
}

{
	my $entry = IWL::Entry->new;

	is($entry->setIcon('foo.jpg')->setId('first_image'), $entry->{image1});
	is_deeply($entry->{image1}->getObject, {
			tag => 'img',
			attributes => {
				src => 'foo.jpg',
				id => 'first_image',
				class => 'entry_image1'
			}
	});
	is($entry->setIconFromStock('IWL_STOCK_OK', 'right', 1)->setId('stock_image'), $entry->{image2});
	is_deeply($entry->{image2}->getObject, {
			tag => 'img',
			attributes => {
				alt => __('OK'),
				src => '/my/skin/darkness/tiny/ok.gif',
				id => 'stock_image',
				class => 'entry_image2',
				style => {
					cursor => 'pointer'
				}
			}
	});
	is($entry->addClearButton, $entry);
	my $clear = __("Clear");
	like($entry->{image2}->getContent, qr(<img (?:(?:alt="$clear"|src="/my/skin/darkness/tiny/clear.gif"|class="entry_image2"|onclick=".*?"|class="entry_image2"|id="entry_\d+_image2"|style="cursor: pointer; ")\s*){6}/>\n)s);
}
