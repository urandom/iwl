use Test::More tests => 3;

use IWL::Tree::Cell;

{
	my $cell = IWL::Tree::Cell->new(id => 'foo');
	is($cell->getContent, '<td id="foo"></td>' . "\n");
}

{
	my $cell = IWL::Tree::Cell->new(type => 'header');
	is($cell->makeSortable, $cell);
	is($cell->getContent, '<th style="cursor: pointer"></th>' . "\n");
}
