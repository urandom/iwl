use Test::More tests => 15;

use IWL::Input;
use IWL::Stash;

{
	my @inputs = IWL::Input->newMultipleFromHash(foo => 'bar', alpha => 'beta');
	is(@inputs, 2);
	is($inputs[0]->getName, 'foo');
	is($inputs[1]->getName, 'alpha');
	is($inputs[0]->getValue, 'bar');
	is($inputs[1]->getValue, 'beta');
}

{
	my $input = IWL::Input->new;
	is($input->setName('foo'), $input);
	is($input->setValue('bar'), $input);
	is($input->getName, 'foo');
	is($input->getValue, 'bar');
}

{
	my $input = IWL::Input->new;
	is($input->setDisabled(1), $input);
	ok($input->isDisabled);
	is($input->getContent, "<input disabled />\n");
}

{
	my $input = IWL::Input->new(name => 'foo', value => 'bar');
	my $stash = IWL::Stash->new;
	ok($input->extractState($stash));
	$stash->setValues(foo => 'alpha');
	ok($input->applyState($stash));
	is($input->getValue, 'alpha');
}
