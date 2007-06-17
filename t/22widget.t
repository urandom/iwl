use Test::More tests => 9;

use IWL::Widget;

{
	my @widgets = IWL::Widget->newMultiple(10);
	is (scalar @widgets, 10);
	isa_ok($widgets[7], 'IWL::Widget');

	@widgets = IWL::Widget->newMultiple({id => 'foo'}, {id => 'bar', class => 'foo'});
	is (scalar @widgets, 2);
	isa_ok($widgets[0], 'IWL::Widget');
}

{
	my $widget = IWL::Widget->new;
	is($widget->signalConnect(click => 'alert(1)'), $widget);
	is($widget->signalConnect('mousewheel'), $widget);
	ok(!$widget->signalConnect('some_signal'));

	$widget->signalConnect(click => 'alert(this)');
	is($widget->signalDisconnect(click => 'alert(1)'), $widget);
	is($widget->getContent, '< onclick="; alert(this)"></>' . "\n");
}
