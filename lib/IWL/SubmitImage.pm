#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::SubmitImage;

use strict;

use base qw(IWL::Image IWL::Input);

=head1 NAME

IWL::SubmitImage - an image used as a submit button

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Input> -> L<IWL::SubmitImage>

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Image> -> L<IWL::SubmitImage>

=head1 DESCRIPTION

The SubmitImage widget functions as a widget, which when pressed, activates the submit of the form

=head1 CONSTRUCTOR

IWL::SubmitImage->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);

    $self->{_tag} = "input";
    $self->{_signals} = {
        %{$self->{_signals}},
        change => 1,
        select => 1,
        blur   => 1,
        focus  => 1,
    };

    $self->setAttribute(type => 'image');

    return $self;
}

1;

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2008  Viktor Kojouharov. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
