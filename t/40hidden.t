use Test::More tests => 2;

use IWL::Hidden;

my $hidden = IWL::Hidden->new;
like($hidden->getContent, qr(^<input (?:(?:type="hidden"|class="hidden")\s*){2}/>\n$));
is_deeply($hidden->getObject, {
		tag => 'input',
		attributes => {
			type => 'hidden',
			class => 'hidden'
		}
});
