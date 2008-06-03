#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::List::Definition;

use strict;

use base 'IWL::Container';

=head1 NAME

IWL::List::Definition - a defintion list item

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container> -> L<IWL::List::Definition>

=head1 DESCRIPTION

Provides a the B<dt> and B<dd> markup elements for use with definition lists.

=head1 CONSTRUCTOR

IWL::List::Definition->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<type>

key [default, the I<dt> element], value [the I<dd> element]

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $type;

    if ($args{type} eq 'value') {
        $type = 'value';
    } else {
        $type = 'key';
    }

    delete $args{type};
    my $self = $class->SUPER::new(%args);

    if ($type eq 'value') {
        $self->{_tag} = 'dd';
    } else {
        $self->{_tag} = 'dt';
    }
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
