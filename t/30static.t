use Test::More tests => 13;

use IWL::Static;
use IWL::Config '%IWLConfig';
use IWL::Widget;
use File::Spec;

$IWLConfig{RESPONSE_CLASS} = 'FooBar';
my $output = {};
my $s = IWL::Static->new(parameters => {IWLStaticURI => $0});
is($s->addURI(((File::Spec->splitpath($0))[1] => 0)), $s);
is($s->handleRequest, $s);
ok(length $output->{content});
ok(exists $output->{header});
ok(exists $output->{header}{'Last-Modified'});
like($output->{header}{'Content-length'}, qr(^\d+$));
like($output->{header}{'Content-type'}, qr(^[\w\-.+]+/[\w\-.+]+(;.*)?$));
like($output->{header}{ETag}, qr(^[0-9a-fA-F]+-[0-9a-fA-F]+$));
my @scripts = qw(/foo/bar.js ./t/iwl.conf);
is_deeply([$s->addRequest(@scripts)], [@scripts]);
$IWLConfig{STATIC_URI_SCRIPT} = 'foo';
is_deeply([$s->addRequest(@scripts)], [
    '/foo/bar.js', 'foo?IWLStaticURI=./t/iwl.conf'
]);
my $script = './t/iwl.conf';
is_deeply([$s->addRequest($script)], ['foo?IWLStaticURI=./t/iwl.conf']);

$IWLConfig{STATIC_URI_SCRIPT} = '';
$IWLConfig{STATIC_LABEL} = 1;
like($s->addRequest('./t/iwl.conf'), qr|\./t/iwl\.conf\?[0-9a-fA-F]+-[0-9a-fA-F]+|);
$IWLConfig{JS_DIR} = 'share/jscript/dist';
my $o = IWL::Widget->new->requiredJs('prototype.js')->getObject;
like($o->{scripts}[0]{attributes}{src}, qr|share/jscript/dist/prototype\.js\?[0-9a-fA-F]+-[0-9a-fA-F]+|);

package FooBar;

sub new { return bless {}, shift }
sub send {
    my ($self, %args) = @_;
    $output = {};
    $output->{header} = $args{header} if defined $args{header};
    $output->{content} = $args{content} if defined $args{content};
}
