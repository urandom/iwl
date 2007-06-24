use Test::More tests => 3;

use IWL::Page::Meta;

my $meta = IWL::Page::Meta->new;
ok(!$meta->appendChild(IWL::Object->new));
is($meta->set('foo', 'bar'), $meta);
my @result = $meta->get;
is_deeply(\@result, ['foo', 'bar']);
