use Test::More tests => 33;

use IWL::Widget;
use IWL::Config '%IWLConfig';

$IWLConfig{STRICT_LEVEL} = 2;

{
	my $widget = IWL::Widget->new;
	is($widget->signalConnect(click => 'alert(1)'), $widget);
    is($widget->signalConnect('mousewheel'), $widget);
	ok(!$widget->signalConnect('some_signal'));

	$widget->signalConnect(click => 'alert(this)');
	is($widget->signalDisconnect(click => 'alert(1)'), $widget);
	is($widget->getContent, '< onclick="; alert(this)"></>' . "\n");
	$widget->signalConnect(click => 'window.alert(2)');
	$widget->signalConnect(click => 'window.alert(this)');
	$widget->signalConnect(mouseover => 'alert("this")');
	is($widget->signalDisconnect('click'), $widget);
	is($widget->getContent, '< onmouseover="alert(&quot;this&quot;)"></>' . "\n");
	is($widget->signalDisconnect, $widget);
	is($widget->getContent, '<></>' . "\n");
}

{
	my $widget = IWL::Widget->new;

	is($widget->setStyle(width => '80px'), $widget);
	$widget->setStyle(display => 'none');

	is($widget->getStyle('width'), '80px');
	like($widget->getContent, qr/< style="(?:[\w-]+:\s*[\w-]+;*\s*){2}"><\/>/);

	is($widget->deleteStyle('width'), $widget);
	is($widget->getContent, '< style="display: none"></>' . "\n");
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
	like($widget->getContent, qr/< (?:(?:class="alpha bar"|id="foo")\s*){2}><\/>/);
}

{
	my $widget = IWL::Widget->new;

	is($widget->setName('My name'), $widget);
	is($widget->setTitle('My title'), $widget);
	like($widget->getContent, qr/< (?:(?:name="My name"|title="My title")\s*){2}><\/>/);
}

{
    my $a = IWL::Widget->new->setAttributes(id => 'top', class => 'object');

    my $a_a = IWL::Widget->new->setAttributes(id => 'middle', class => 'object middle');
    my $a_a_a = IWL::Widget->new->setAttributes(id => 'bottom1', class => 'object bottom');
    my $a_a_b = IWL::Widget->new->setAttributes(id => 'bottom2', class => 'object bottom');

    $a->appendChild($a_a->appendChild($a_a_a, $a_a_b));
    is($a->down({id => 'bottom2'}), $a_a_b);
    ok(!$a->down({id => 'bottom2', class => 'middle'}));
    is($a->down({id => 'middle', class => 'middle'}), $a_a);
    ok(!$a->down({id => 'middle', class => 'top'}));
    is_deeply([$a->down({class => 'bottom'})], [$a_a_a, $a_a_b]);
}

