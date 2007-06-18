use Test::More tests => 28;

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

{
	my $widget = IWL::Widget->new;

	is($widget->setStyle(width => '80px'), $widget);
	$widget->setStyle(display => 'none');

	is($widget->getStyle('width'), '80px');
	is($widget->getContent, '< style="width: 80px; display: none; "></>' . "\n");

	is($widget->deleteStyle('width'), $widget);
	is($widget->getContent, '< style="display: none; "></>' . "\n");
}

{
	my $widget = IWL::Widget->new;

	is($widget->setId('foo'), $widget);
	is($widget->getId, 'foo');

	is($widget->setClass('foo'), $widget);
	is($widget->appendClass('bar'), $widget);
	is($widget->prependClass('alpha'), $widget);
	is($widget->getClass, 'alpha foo bar');
	ok($widget->hasClass('bar'));
	ok(!$widget->hasClass('baz'));
	is($widget->removeClass('foo'), $widget);
	ok(!$widget->hasClass('foo'));
	is($widget->getContent, '< class="alpha bar" id="foo"></>' . "\n");
}

{
	my $widget = IWL::Widget->new;

	is($widget->setName('My name'), $widget);
	is($widget->setTitle('My title'), $widget);
	is($widget->getContent, '< name="My name" title="My title"></>' . "\n");
}
