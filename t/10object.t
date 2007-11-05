use Test::More tests => 30;

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
	is($object->getChildren, $object->{childNodes}, 'getChildren()');

	is($object->{childNodes}[3], $child2_5, 'Inserting after another object');
	is($object->{childNodes}[0], $first_child, 'Prepending objects');
	is($object, $child2->{parentNode}, 'Parent link');
	is($object, $child2->getParent, 'getParent()');
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

    is_deeply($object->getObject, {attributes => {
        one => "two%20three",
        alpha => "&lt;beta&gt;",
        tango => "фокс <трот>",
        foo => "bar"
            }});
    like($object->getContent, qr(^< (?:(?:one="two%20three"|alpha="&lt;beta&gt;"|tango="фокс <трот>"|foo="bar")\s*){4}></>\n$));
	ok($object->hasAttribute('foo'), 'Exists attribute "foo"');
	ok(!$object->hasAttribute('bar'), 'Exists attribute "bar"');

	$object->deleteAttribute('foo');
	ok(!$object->hasAttribute('foo'), 'Delete attribute "foo"');
}

{
    my $object = IWL::Object->new;
    my $child1 = IWL::Object->new;
    my $child2 = IWL::Object->new;

    $object->setAttribute(foo => 'bar');
    $child1->setAttribute(alpha => 'beta');
    $child2->setAttribute(one => 'two');
    
    $object->appendChild($child1, $child2);

    my $clone = $object->clone;

    isa_ok($clone, 'IWL::Object');
    isnt($clone, $object);
    isnt($clone->{childNodes}[0], $object->{childNodes}[0]);
    isnt($clone->{childNodes}[1], $object->{childNodes}[1]);
    is_deeply($clone, $object);
    is_deeply($clone->{childNodes}[0], $object->{childNodes}[0]);
    is_deeply($clone->{childNodes}[1], $object->{childNodes}[1]);
    is($clone->{childNodes}[1]->{parentNode}, $clone);
}
