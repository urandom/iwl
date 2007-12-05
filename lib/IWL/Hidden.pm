#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Hidden;

use strict;

use base 'IWL::Input';

=head1 NAME

IWL::Hidden - a hidden value field

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Input> -> L<IWL::Hidden>

=head1 DESCRIPTION

While not really a widget, the hidden input allows to pass hidden data to the form.

=head1 CONSTRUCTOR

IWL::Hidden->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);

    $self->setAttribute(type => 'hidden');
    $self->{_defaultClass} = 'hidden';

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
