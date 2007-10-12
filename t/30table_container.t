use Test::More tests => 4;

use IWL::Table::Container;

{
	my $c = IWL::Table::Container->new;
	$c->appendChild(IWL::Widget->new);
	is($c->getContent, "<tbody><></>\n</tbody>\n");
}

{
	my $c = IWL::Table::Container->new(type => 'body');
	$c->appendChild(IWL::Widget->new);
    like($c->getJSON, qr(^{(?:(?:"tag": "tbody"|"children": \[\{\}\])(?:, )?){2}}$));
}

{
	my $c = IWL::Table::Container->new(type => 'header');
	$c->appendChild(IWL::Widget->new);
	is_deeply($c->getObject, {children => [{}], tag => 'thead'});
}

{
	my $c = IWL::Table::Container->new(type => 'footer');
	$c->appendChild(IWL::Widget->new);
	is_deeply($c->getObject, {tag => 'tfoot', children => [{}]});
}
