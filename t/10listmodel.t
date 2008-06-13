use Test::More qw(no_plan);

BEGIN { use_ok('IWL::ListModel') }

my $t = IWL::ListModel->new;
isa_ok($t, 'IWL::ListModel');
ok($t->bad);
$t = IWL::ListModel->new([{type => 'FOO'}]);
isa_ok($t, 'IWL::ListModel');
ok($t->bad);
$t = IWL::ListModel->new([{type => 'STRING', name => 'Name'}, {type => 'FLOAT', name => 'Count'}]);
isa_ok($t, 'IWL::ListModel');
ok(!$t->bad);

is($t->dataReader(file => './t/data.json', type => 'json', valuesProperty => 'results'), $t);
is(@{$t->{rootNodes}}, 7);
is($t->getNodeByPath([1]), $t->{rootNodes}[1]);

my $count = 0;
$t->each(sub { $count++ });
is($count, 7);

isa_ok($t->{rootNodes}[6]->remove, 'IWL::ListModel::Node');
is(@{$t->{rootNodes}}, 6);
my $first = $t->{rootNodes}[0];
my $last = $t->{rootNodes}[-1];
isa_ok($t->prependNode, 'IWL::ListModel::Node');
is($t->{rootNodes}[1], $first);
isa_ok($t->appendNode, 'IWL::ListModel::Node');
is($t->{rootNodes}[-2], $last);
isa_ok($t->insertNode(4), 'IWL::ListModel::Node');
is_deeply([$first->getValues], ["Sample", 15]);
is($first->setValues(1, 42, 0, "Hello"), $first);
is_deeply([$first->getValues], ["Hello", 42]);
is_deeply([$first->getValues(1)], [42]);
ok($first->getAttributes('id'));
is($first->setAttributes(foo => 1, bar => 'aaa'), $first);
is(keys %{{$first->getAttributes}}, 3);
is_deeply([$first->getAttributes('bar', 'foo')], ['aaa', 1]);

my $t2 = $t->new(data => $t->toObject);
isa_ok($t, 'IWL::ListModel');
ok(!$t->bad);
is(@{$t->{rootNodes}}, 9);
