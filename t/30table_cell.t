use Test::More tests => 2;

use IWL::Table::Cell;

{
	my $cell = IWL::Table::Cell->new(id => 'foo');
	is($cell->getContent, '<td id="foo"></td>' . "\n");
}

{
	my $cell = IWL::Table::Cell->new(type => 'header');
	is($cell->getContent, '<th></th>' . "\n");
}
