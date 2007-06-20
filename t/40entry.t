use Test::More tests => 6;

use IWL::Entry;

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
