use Test::More tests => 24;

use IWL::Entry;

use Locale::TextDomain qw(org.bloka.iwl);

my $entry = IWL::Entry->new;

{
	my $entry = IWL::Entry->new;

	is($entry->setPassword(1), $entry);
	is($entry->setReadonly(1), $entry);
	is($entry->setText('Some text'), $entry);
    is($entry->setValue('Something', 'else'), $entry);
	is($entry->setDefaultText('Default text'), $entry);
	is($entry->setMaxLength(10), $entry);
	is($entry->setSize(3), $entry);

	ok($entry->isPassword);
	ok($entry->isReadonly);
	is($entry->getText, 'Something');
	is($entry->getDefaultText, 'Default text');
	is($entry->getMaxLength, 10);
	is($entry->getSize, 3);

	like($entry->getContent, qr(^<table (?:(?:class="entry password"|cellspacing="0"|cellpadding="0"|id="(entry_\d+)")\s*){4}><tbody><tr [^>]+><td></td>
<td><input (?:(?:maxlength="10"|value="Something"| size="3"|readonly="true"|class="entry_text entry_text_default"|type="password"|id="\1_text")\s*){7}/>
</td>
<td></td>
</tr>
</tbody>
.*entry.js.*
<script.*IWL.Entry.create.*\1.*"blurValue": "else".*</script>
</table>
)s);
}

{
	my $entry = IWL::Entry->new;

	is($entry->setIcon('foo.jpg')->setId('first_image'), $entry->{image1});
	is_deeply($entry->{image1}->getObject, {
			tag => 'img',
			attributes => {
				src => 'foo.jpg',
                alt => 'foo',
				id => 'first_image',
				class => 'image'
			}
	});
	is($entry->setIconFromStock('IWL_STOCK_OK', 'right', 1)->setId('stock_image'), $entry->{image2});
	is_deeply($entry->{image2}->getObject, {
			tag => 'img',
			attributes => {
				alt => __('OK'),
				src => '/my/skin/darkness/tiny/ok.gif',
				id => 'stock_image',
				class => 'image',
				style => {
					cursor => 'pointer'
				}
			}
	});
	is($entry->addClearButton, $entry);
    $entry->setId('clear_entry');
    is_deeply($entry->{image2}->getObject, {
        tag => 'img',
        attributes => {
            alt => __('Clear'),
            src => '/my/skin/darkness/tiny/clear.gif',
            style => { cursor => 'pointer' },
            id => 'clear_entry_right',
            class => 'image'
        }
    });
    $entry->getContent;
    ok($entry->{image1}->hasClass('entry_left'));
    ok($entry->{image2}->hasClass('entry_right'));
}

{
	my $entry = IWL::Entry->new(id => 'foo');

    is($entry->setValue('bar'), $entry);
	$entry->setAutoComplete('iwl_demo.pl');
	like($entry->getContent, qr(^<table (?:(?:class="entry"|cellspacing="0"|cellpadding="0"|id="foo")\s*){4}><tbody><tr [^>]+><td></td>
<td><input (?:(?:class="entry_text"|id="foo_text"|type="text"|value="bar")\s*){4}/>
</td>
<td></td>
</tr>
</tbody>
.*entry.js.*
<script .*IWL.Entry.create.*foo.*(?:(?:"autoComplete": \["iwl_demo.pl", {}\]|"blurValue": null),?\s*){2}.*</script>
</table>
$)s);
}
