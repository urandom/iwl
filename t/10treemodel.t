use Test::More qw(no_plan);

BEGIN { use_ok('IWL::TreeModel') }

my $t = IWL::TreeModel->new;
isa_ok($t, 'IWL::TreeModel');
ok($t->bad);
$t = IWL::TreeModel->new([{type => 'FOO'}]);
isa_ok($t, 'IWL::TreeModel');
ok($t->bad);
$t = IWL::TreeModel->new([{type => 'STRING', name => 'Name'}, {type => 'FLOAT', name => 'Count'}]);
isa_ok($t, 'IWL::TreeModel');
ok(!$t->bad);

is($t->dataReader(file => './t/data.json', type => 'json', valuesProperty => 'results'), $t);
is(@{$t->{rootNodes}}, 7);
is(@{$t->{rootNodes}[0]{childNodes}}, 2);
is($t->getNodeByPath([1]), $t->{rootNodes}[1]);
is($t->getNodeByPath([2,2]), $t->{rootNodes}[2]{childNodes}[2]);
ok!($t->isFlat);

my $count = 0;
$t->each(sub { $count++ });
is($count, 21);

isa_ok($t->{rootNodes}[6]->remove, 'IWL::TreeModel::Node');
is(@{$t->{rootNodes}}, 6);
my $first = $t->{rootNodes}[0];
my $last = $t->{rootNodes}[-1];
isa_ok($t->prependNode, 'IWL::TreeModel::Node');
is($t->{rootNodes}[1], $first);
isa_ok($t->appendNode, 'IWL::TreeModel::Node');
is($t->{rootNodes}[-2], $last);
$first = $t->{rootNodes}[1]{childNodes}[0];
is_deeply($first->getPath, [1, 0]);
is($first->getDepth, 1);
isa_ok($t->insertNode($t->{rootNodes}[1], 0), 'IWL::TreeModel::Node');
is(@{$t->{rootNodes}[1]{childNodes}}, 3);
is($t->{rootNodes}[1]{childNodes}[1], $first);
is_deeply($first->getPath, [1, 1]);
is_deeply([$first->getValues], ["Foo child 1", 15.1]);
is($first->setValues(1, 42, 0, "Hello"), $first);
is_deeply([$first->getValues], ["Hello", 42]);
is_deeply([$first->getValues(1)], [42]);
ok($first->getAttributes('id'));
is($first->setAttributes(foo => 1, bar => 'aaa'), $first);
is(keys %{{$first->getAttributes}}, 3);
is_deeply([$first->getAttributes('bar', 'foo')], ['aaa', 1]);
ok($first->isDescendant($t->{rootNodes}[1]));
ok(!$first->isDescendant($t->{rootNodes}[0]));
ok($t->{rootNodes}[1]->isAncestor($first));
ok(!$t->{rootNodes}[0]->isAncestor($first));
