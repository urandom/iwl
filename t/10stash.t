use Test::More tests => 24;

use IWL::Stash;

{

    my $ref_state = IWL::Stash->new;
    is($ref_state->setValues(foo => 'bar'), $ref_state);
    is($ref_state->setValues(bar => 'baz', 'bazoo'), $ref_state);
    $ref_state->setDirty(0);

    my $num_keys = $ref_state->keys;
    is(2, $num_keys, "number of keys");

    my $hash_state = IWL::Stash->new(
        foo => 'bar',
        bar => [qw (baz bazoo)]
    );

    is_deeply($ref_state, $hash_state, "newFromHash constructor");

    my $hash_ref_state = IWL::Stash->new(
        {
            foo => 'bar',
            bar => [
                qw (baz
                  bazoo)
            ]
        }
    );

    is_deeply($ref_state, $hash_ref_state, "newFromHashReference constructor");

    require CGI;

    # We have no data, so this is safe.
    local %ENV;
    $ENV{REQUEST_METHOD} = 'GET';
    $ENV{QUERY_STRING}   = '';
    my $cgi = CGI->new;
    $cgi->param(-name => 'foo', -value => 'bar');
    $cgi->param(-name => 'bar', -value => [qw (baz bazoo)]);
    my $cgi_state = IWL::Stash->new($cgi);
    is_deeply($ref_state, $cgi_state, "newFromCGI constructor");

    my $clone = IWL::Stash->new($ref_state);
    is_deeply($ref_state, $clone, "clone");
}

{
    my $state = IWL::Stash->new(my_key => [qw (a b)]);

    my $value = $state->shiftValue('my_key');
    is('a', $value);
    ok(scalar $state->existsKey('my_key'));
    my @values = $state->getValues('my_key');
    is_deeply(['b'], \@values);

    $value = $state->shiftValue('my_key');
    is('b', $value);
    ok(!(scalar $state->existsKey('my_key')));
}

{
    my $state = IWL::Stash->new(my_key => [qw (a b)]);

    my $value = $state->popValue('my_key');
    is('b', $value);
    ok(scalar $state->existsKey('my_key'));
    my @values = $state->getValues('my_key');
    is_deeply(['a'], \@values);

    $value = $state->popValue('my_key');
    is('a', $value);
    ok(!(scalar $state->existsKey('my_key')));
}

{
    my $state   = IWL::Stash->new(my_key => [qw (a b)]);
    my $compare = IWL::Stash->new($state);
    my $merger1 = IWL::Stash->new(new1 => 'foobar');
    is($state->mergeState($merger1), $state);
    is($compare->pushValues(new1 => 'foobar'), $compare);
    is_deeply($compare, $state, "mergeState does not create new keys");

    my $merger2 = IWL::Stash->new(my_key => 'barbaz');
    $state->mergeState($merger2);
    $compare->pushValues(my_key => 'barbaz');
    is_deeply($compare, $state, "mergeState does not overwrite existing keys");
}

{
    my $state    = IWL::Stash->new(my_key => [qw(a b)]);
    my $override = IWL::Stash->new(new1 => 'foobar', my_key => 'a');
    is_deeply([$state->getValues('my_key')], [qw(a b)]);
    is($state->overrideState($override), $state);
    is_deeply([$state->getValues('my_key')], [qw(a)]);
}
