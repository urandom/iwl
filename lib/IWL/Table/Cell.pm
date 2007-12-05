#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Table::Cell;

use strict;

use base 'IWL::Widget';

=head1 NAME

IWL::Table::Cell - a cell widget for a table

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Table::Cell>

=head1 DESCRIPTION

The Cell widget provides a cell for IWL::Table. It shouldn't be used standalone.

=head1 CONSTRUCTOR

IWL::Table::Cell->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<E<lt>tdE<gt>> and B<E<lt>thE<gt>> markup would have, and also:

=over 4

=item B<type>

I<header> or regular if unspecified.

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->{_tag} =
      $args{type} && $args{type} eq "header" ? "th" : "td";
    delete $args{type};
    $self->_constructorArguments(%args);

    # the column number the cell is in
    $self->{_colNum} = 0;

    # the row the cell is in
    $self->{_row} = undef;

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
