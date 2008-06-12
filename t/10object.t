use Test::More tests => 126;

use IWL::Object;
use IWL::Config '%IWLConfig';

$IWLConfig{STRICT_LEVEL} = 2;
my $output;

{
	my @objects = IWL::Object->newMultiple(10);
	is (scalar @objects, 10);
	isa_ok($objects[7], 'IWL::Object');

	@objects = IWL::Object->newMultiple({id => 'foo'}, {id => 'bar', class => 'foo'});
	is (scalar @objects, 2);
	isa_ok($objects[0], 'IWL::Object');
}

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

    is($object->removeChild($child3), $object);
	ok(!$object->{childNodes}[4]);
    is($object->removeChild($child1, $first_child, $child2_5), $object);
	is(scalar @{$object->{childNodes}}, 1);
    is($child2->remove, $child2);
	is(scalar @{$object->{childNodes}}, 0);

	isa_ok($object->setChild(IWL::Object->new), 'IWL::Object', 'Returns itself');
	is(scalar @{$object->{childNodes}}, 1, 'setChild');
    ok(!$object->prependChild($object));
    ok(!$object->appendChild($object));
    ok(!$object->setChild($object));
    ok(!$object->insertAfter($child1, $object));
}

{
	my $object = IWL::Object->new;

    isa_ok($object->getResponseObject, 'IWL::Response');
	is($object->getContent, "<></>\n");
	is_deeply($object->getObject, {});
	is($object->getJSON, '{}');
}

{
    my $o = IWL::Object->new;
    tie *STDOUT, 'PRINT_TEST';
    $o->send(type => 'html');
    is($output, "Content-type: text/html; charset=utf-8\n\n<></>\n");
    $o->send(type => 'json');
    like($output, qr|X-IWL: 1|);
    like($output, qr|Content-type: application/json|);
    $o->send(type => 'text');
    is($output, "Content-type: text/plain\n\n<></>\n");
    $o->send(type => 'html', header => {test => 'success'});
    like($output, qr|test: success|);
    like($output, qr|Content-type: text/html; charset=utf-8|);
    $o->send(type => 'json', header => {'X-IWL' => 42});
    like($output, qr|X-IWL: 42|);
    like($output, qr|Content-type: application/json|);
    $o->send(type => 'text', header => {'Content-type' => 'plain text, really!'});
    is($output, "Content-type: plain text, really!\n\n<></>\n");

    $o->send(type => 'html', static => 1);
    like($output, qr|ETag: [0-9A-Fa-f]+|);
    like($output, qr|<></>\n$|, 'ETag content');
    untie *STDOUT;
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

{
    require IWL::JSON;

    is(IWL::JSON::toJSON({a => IWL::Object->new->setAttribute(foo => 1)}), '{"a": {"attributes": {"foo": 1}}}');
    is(IWL::JSON::toJSON([IWL::Object->newMultiple(3)]), '[{}, {}, {}]');
}

{
    my $o = IWL::Object->new;
    $o->require(css => 'foo.css', js => [qw(base.js foo.js)]);
    my $data = $o->getObject;
    is($data->{children}[0]{children}[0]{text}, qq(\@import "/my/skin/darkness/foo.css";\n));
    is($data->{children}[1]{attributes}{src}, '/jscript/dist/prototype.js');
    is($data->{children}[6]{attributes}{src}, '/jscript/foo.js');

    $o = $o->new;
    $o->require(css => 'foo.css', js => [qw(base.js foo.js)]);
    $o->unrequire(js => 'base.js');
    $data = $o->getObject;
    is($data->{children}[0]{children}[0]{text}, qq(\@import "/my/skin/darkness/foo.css";\n));
    is($data->{children}[1]{attributes}{src}, '/jscript/foo.js');

    $o = $o->new;
    $o2 = IWL::Test::Object2->new;
    $o->appendChild($o2);
    $data = $o->getObject;
    is($data->{children}[0]{children}[0]{children}[0]{text}, qq(\@import "/my/skin/darkness/foo.css";\n));
    is($data->{children}[1]{attributes}{src}, '/jscript/foo.js');
}

{
    my $a = IWL::Object->new->setAttributes(id => 'top', class => 'object');

    my $a_a = IWL::Object->new->setAttributes(id => 'middle', class => 'object');
    my $a_a_a = IWL::Object->new->setAttributes(id => 'bottom1', class => 'object');
    my $a_a_b = IWL::Object->new->setAttributes(id => 'bottom2', class => 'object');
    my $a_a_c = IWL::Test::Object->new->setAttributes(id => 'bottom3', class => 'object');

    my $a_b = IWL::Test::Object->new->setAttributes(id => 'test_middle', class => 'test_object');
    my $a_b_a = IWL::Test::Object->new->setAttributes(id => 'test_bottom', class => 'test_object');
    my $a_b_a_a = IWL::Object->new->setAttributes(foo => 'bar', class => 'test_object');

    $a->appendChild($a_a->appendChild($a_a_a, $a_a_b, $a_a_c), $a_b->appendChild($a_b_a->appendChild($a_b_a_a)));

    ok(!$a->match);
    ok(!$a->match({}));
    ok($a->match({package => 'IWL::Object'}));
    ok(!$a->match({package => 'IWL::Test::Object'}));
    ok($a->match('not', {package => 'IWL::Test::Object'}));
    ok(!$a->match('not', {package => 'IWL::Test::Object'}, {attribute => [class => 'foo']}));
    ok($a->match('not', {package => 'IWL::Test::Object'}, {attribute => [class => 'foo']}, 'or', {attribute => [id => 'top']}, {package => 'IWL::Object'}));
    ok(!$a->match('not', {package => 'IWL::Test::Object'}, {attribute => [class => 'foo']}, 'or', {attribute => [id => 'top']}, {package => 'IWL::Test::Object2'}));
    ok($a->match('not', {package => 'IWL::Test::Object'}, {attribute => [class => 'foo']}, 'or', {attribute => [id => 'top']}, 'not', {package => 'IWL::Test::Object2'}));

    is_deeply([$a_b_a_a->getAncestors], [$a_b_a, $a_b, $a]);
    ok(!$a_b_a_a->getDescendants);

    ok(!$a->getAncestors);
    is_deeply([$a->getDescendants], [$a_a, $a_a_a, $a_a_b, $a_a_c, $a_b, $a_b_a, $a_b_a_a]);

    ok(!$a_a_c->getNextSiblings);
    is_deeply([$a_a_a->getNextSiblings], [$a_a_b, $a_a_c]);

    ok(!$a_a_a->getPreviousSiblings);
    is_deeply([$a_a_c->getPreviousSiblings], [$a_a_b, $a_a_a]);

    ok(!$a_a_a->up({package => 'IWL::Test::Object'}));
    ok(!$a_a_a->up({attribute => [id => 'asdlkj']}));

    is(scalar $a_a_a->up, $a_a);
    is_deeply([$a_a_a->up], [$a_a, $a]);
    is($a_a_a->up({attribute => [id => qr/midd/]}), $a_a);
    is($a_a_a->up(options => {last => 1}), $a);
    is($a_a_a->up(options => {last => 1}, criteria => [{package => 'IWL::Test::Object'}]), $a);
    is($a_b_a_a->up(options => {last => 1}, criteria => [{package => 'IWL::Test::Object'}]), $a_b);
    is($a_a_a->up({attribute => [id => 'top']}, {attribute => [class => qr/obj/]}), $a);
    is($a_a_a->up({attribute => [id => 'middle']}, {package => 'IWL::Object'}), $a_a);
    ok(!$a_a_a->up({attribute => [id => 'middle']}, {package => 'IWL::Test::Object'}));
    ok($a_a_a->up({attribute => [id => 'middle']}, 'not', {package => 'IWL::Test::Object'}), $a_a);

    is(scalar $a_b_a_a->up({package => 'IWL::Test::Object'}), $a_b_a);
    is_deeply([$a_b_a_a->up({package => 'IWL::Test::Object'})], [$a_b_a, $a_b]);
    is_deeply([$a_b_a_a->up({attribute => [class => 'test_object']})], [$a_b_a, $a_b]);

    ok(!$a->down({package => 'IWL::Widget'}));
    is(scalar $a->down, $a_a);
    is_deeply([$a->down], [$a_a, $a_a_a, $a_a_b, $a_a_c, $a_b, $a_b_a, $a_b_a_a]);
    is($a->down(options => {last => 1}), $a_b_a_a);
    is($a->down(options => {last => 1}, criteria => [{package => 'IWL::Test::Object'}]), $a_b_a);
    is($a->down(options => {last => 1}, criteria => [{package => 'IWL::Test::Object2'}]), $a_b_a_a);
    is($a->down({package => 'IWL::Object'}), $a_a);
    is_deeply([$a->down({package => 'IWL::Test::Object'})], [$a_a_c, $a_b, $a_b_a]);
    is($a->down({package => 'IWL::Test::Object'}, {attribute => [id => 'test_middle']}, {attribute => [class => 'test_object']}), $a_b);

    ok(!$a_a_a->next({package => 'IWL::Test'}));
    is(scalar $a_a_a->next, $a_a_b);
    is_deeply([$a_a_a->next], [$a_a_b, $a_a_c]);
    is($a_a_a->next(options => {last => 1}), $a_a_c);
    is($a_a_a->next(options => {last => 1}, criteria => [{attribute => [id => 'bottom2']}]), $a_a_b);
    is($a_a_a->next(options => {last => 1}, criteria => [{package => 'IWL::Test::Object'}]), $a_a_c);
    is($a_a_a->next({package => 'IWL::Test::Object'}), $a_a_c);
    ok(!$a_a_a->next({package => 'IWL::Test::Object'}, {attribute => [id => 'foo']}));
    is($a_a_a->next({package => 'IWL::Test::Object'}, {attribute => [id => 'bottom3']}, {attribute => [class => 'object']}), $a_a_c);
    is_deeply([$a_a_a->next({attribute => [class => 'object']})], [$a_a_b, $a_a_c]);

    ok(!$a_a_c->previous({package => 'IWL::Test'}));
    is(scalar $a_a_c->previous, $a_a_b);
    is_deeply([$a_a_c->previous], [$a_a_b, $a_a_a]);
    is($a_a_c->previous(options => {last => 1}), $a_a_a);
    is($a_a_c->previous(options => {last => 1}, criteria => [{attribute => [id => 'bottom2']}]), $a_a_b);
    is($a_a_c->previous(options => {last => 1}, criteria => [{package => 'IWL::Test::Object'}]), $a_a_a);
    is($a_a_c->previous({package => 'IWL::Object'}), $a_a_b);
    ok(!$a_a_c->previous({package => 'IWL::Test::Object'}, {attribute => [id => 'foo']}));
    is($a_a_c->previous({package => 'IWL::Object'}, {attribute => [id => 'bottom1']}, {attribute => [class => 'object']}), $a_a_a);
    is_deeply([$a_a_c->previous({attribute => [class => 'object']})], [$a_a_b, $a_a_a]);
}

package PRINT_TEST;

sub TIEHANDLE {
	my $self = {};
	bless $self, shift;

	return $self;
}

sub PRINT {
	my $self = shift;
    $output = $_[0];
}

package IWL::Test::Object;

use base 'IWL::Object';

package IWL::Test::Object2;

use base 'IWL::Object';

sub _realize {
    my $self = shift;
    $self->require(js => 'foo.js', css => 'foo.css');
    $self->SUPER::_realize;
}
