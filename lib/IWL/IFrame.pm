#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::IFrame;

use strict;

use base 'IWL::Widget';

=head1 NAME

IWL::IFrame - a B<E<lt>iframeE<gt>> container

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::IFrame>

=head1 DESCRIPTION

The IFrame widget is a basic B<E<lt>iframeE<gt>> element in markup notation. It is used to as a container for inline L<IWL::Page> widgets

=head1 CONSTRUCTOR

IWL::IFrame->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<E<lt>iframeE<gt>> markup would have.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();
    $self->{_tag} = "iframe";
    $self->_constructorArguments(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<set> (B<SRC>)

Set sets the given source for the IFrame widget.

Parameters: B<SRC> - the source for the IFrame 

=cut

sub set {
    my ($self, $src) = @_;

    return $self->setAttribute(src => $src, 'uri');
}

=item B<getSrc>

Returns the URL of the IFrame

=cut

sub getSrc {
    shift->getAttribute('src', 1);
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
