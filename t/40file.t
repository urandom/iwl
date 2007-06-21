use Test::More tests => 4;

use IWL::File;

my $file = IWL::File->new;
is($file->setAccept('*.pl'), $file);
is($file->getAccept, '*.pl');
like($file->getContent, qr(^<input (?:(?:accept="\*\.pl"|type="file"|class="file")\s*){3}/>\n$));
is_deeply($file->getObject, {
		tag => 'input',
		attributes => {
			class => 'file',
			type => 'file',
			accept => '*.pl'
		}
});
