#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Response;

use strict;

use base 'IWL::Error';

use IWL::Config '%IWLConfig';

=head1 NAME

IWL::Response - abstract response output

=head1 DESCRIPTION

The Response module provides an abstract layer for issuing server responses.

=head1 CONSTRUCTOR

IWL::Response->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values:

=cut

sub new {
    return bless {}, shift;
}

=head1 METHODS

=over 4

=item B<send> ([B<%ARGS>])

Sends a response to the server.

Where B<%ARGS> is an optional hash parameter with with key-values:

=over 8

=item B<content>

The content of the response, as a string

=item B<header>

The response header, as a hashref.

=back

If RESPONSE_CLASS is defined in %IWLConfig, the class is instantiated and its send() method is called.

=cut

sub send {
    my ($self, %args) = @_;
    my $header = $args{header};
    my $content = $args{content};

    if ($IWLConfig{RESPONSE_CLASS}) {
        {
            no strict 'refs';
            eval "require $IWLConfig{RESPONSE_CLASS}" unless *{$IWLConfig{RESPONSE_CLASS} . "::new"}{CODE};
            return $self->_pushFatalError($@) if $@;
        }
        my $response = $IWLConfig{RESPONSE_CLASS}->new;
        $response->send(header => $header, content => $content);
        return $self;
    }

    print(
        ($header && ref $header eq 'HASH'
              ? (join "\n", map {$_ . ": " . $header->{$_}} keys %$header) . "\n\n"
              : ''
        ) . ($content || ''));

    return $self;
}

1;

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2007  Viktor Kojouharov. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
