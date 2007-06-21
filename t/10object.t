use Test::More tests => 19;

use IWL::Object;

{
	my $object = IWL::Object->new;
	my ($child1, $child2, $child3) = (IWL::Object->new, IWL::Object->new, IWL::Object->new);
	my $first_child = IWL::Object->new;
	my $child2_5 = IWL::Object->new;
	is($object->appendChild($child1, $child2, $child3), $object, 'Returns itself');
	is($object->prependChild($first_child), $object, 'Returns itself');
	is($object->insertAfter($child2, $child2_5), $object, 'Returns itself');
	is($object->firstChild, $object->{childNodes}[0]);
	is($object->lastChild, $object->{childNodes}[4]);
	is(scalar @{$object->{childNodes}}, 5, '5 children');

	is($object->{childNodes}[3], $child2_5, 'Inserting after another object');
	is($object->{childNodes}[0], $first_child, 'Prepending objects');
	is($object, $child2->{parentNode}, 'Parent link');
	is($object->{childNodes}[4], $child3, 'Child link');

	isa_ok($object->setChild(IWL::Object->new), 'IWL::Object', 'Returns itself');
	is(scalar @{$object->{childNodes}}, 1, 'setChild');
}

{
	my $object = IWL::Object->new;

	is($object->getContent, "<></>\n");
	is_deeply($object->getObject, {});
	is($object->getJSON, '{}');
}

{
	my $object = IWL::Object->new;

	$object->setAttribute(foo => 'bar');
	$object->setAttribute(alpha => '<beta>', 'html');
	$object->setAttribute(one => 'two three', 'uri');
	$object->setAttribute(tango => 'фокс <трот>', 'none');

	is($object->getContent,
		'< one="two%20three" alpha="&lt;beta&gt;" tango="фокс <трот>" foo="bar"></>' . "\n");
	ok($object->hasAttribute('foo'), 'Exists attribute "foo"');
	ok(!$object->hasAttribute('bar'), 'Exists attribute "bar"');

	$object->deleteAttribute('foo');
	ok(!$object->hasAttribute('foo'), 'Delete attribute "foo"');
}
