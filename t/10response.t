package main;

use Test::More tests => 6;

use IWL::Response;
use IWL::Config '%IWLConfig';

my $output;

{
    my $response = IWL::Response->new;
	tie *STDOUT, 'PRINT_TEST';
    $response->send(content => 'foobar');
    is($output, 'foobar');
    $response->send(header => {foo => 'bar'});
    is($output, "foo: bar\n\n");
    $response->send(content => 'foobar', header => {foo => 'bar'});
    is($output, "foo: bar\n\nfoobar");
    untie *STDOUT;
}

{
    $IWLConfig{RESPONSE_CLASS} = 'FooBar';
    my $response = IWL::Response->new;
    $response->send(content => 'foobar');
    is_deeply($output, {content => 'foobar'});
    $response->send(header => {foo => 'bar'});
    is_deeply($output, {header => {foo => 'bar'}});
    $response->send(content => 'foobar', header => {foo => 'bar'});
    is_deeply($output, {header => {foo => 'bar'}, content => 'foobar'});
}

package FooBar;

sub new { return bless {}, shift }
sub send {
    my ($self, %args) = @_;
    $output = {};
    $output->{header} = $args{header} if defined $args{header};
    $output->{content} = $args{content} if defined $args{content};
}

1;

package PRINT_TEST;

sub TIEHANDLE {
	my $self = {};
	bless $self, shift;
	$self->{_content} = undef;

	return $self;
}

sub PRINT {
	my $self = shift;
    $output = $_[0];
}

1;
