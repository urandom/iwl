#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Table::Container;

use strict;

use base 'IWL::Widget';

=head1 NAME

IWL::Table::Container - a container widget for a table

=head1 INHERITANCE

L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Table::Container>

=head1 DESCRIPTION

The Container widget provides a headers, footers, and a body for IWL::Table. It shouldn't be used standalone.

=head1 CONSTRUCTOR

IWL::Table::Container->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values pairs:

=over 4

=item B<type>

I<header>, I<footer> or I<body> if unspecified.

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    if (!$args{type} || $args{type} eq 'body') {
        $self->{_tag} = "tbody";
    } elsif ($args{type} eq "header") {
        $self->{_tag} = "thead";
    } elsif ($args{type} eq "footer") {
        $self->{_tag} = "tfoot";
    } else {
        $self->{_tag} = "tbody";
    }
    delete $args{type};
    $self->{_removeEmpty} = 1;
    $self->_constructorArguments(%args);

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
