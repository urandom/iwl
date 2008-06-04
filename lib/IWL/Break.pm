#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Break;

use strict;

use base 'IWL::Widget';

=head1 NAME

IWL::Break - A text break widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Break>

=head1 DESCRIPTION

The break widget provides a way to forcefully add line breaks.

=head1 CONSTRUCTOR

IWL::Break->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<<br>> markup would have.


=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);

    $self->{_tag}  = "br";
    $self->{_noChildren} = 1;

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
