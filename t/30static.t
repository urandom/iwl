use Test::More tests => 8;

use IWL::Static;
use IWL::Config '%IWLConfig';
use File::Spec;

$IWLConfig{RESPONSE_CLASS} = 'FooBar';
my $output = {};
my $s = IWL::Static->new(parameters => {IWLStaticPath => $0});
is($s->addPath(((File::Spec->splitpath($0))[1] => 0)), $s);
is($s->handleRequest, $s);
ok(length $output->{content});
ok(exists $output->{header});
ok(exists $output->{header}{'Content-length'});
ok(exists $output->{header}{'Content-type'});
ok(exists $output->{header}{'Last-Modified'});
ok(exists $output->{header}{'ETag'});

package FooBar;

sub new { return bless {}, shift }
sub send {
    my ($self, %args) = @_;
    $output = {};
    $output->{header} = $args{header} if defined $args{header};
    $output->{content} = $args{content} if defined $args{content};
}
