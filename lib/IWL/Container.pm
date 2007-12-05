#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Container;

use strict;

use base 'IWL::Widget';

=head1 NAME

IWL::Container - a container widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container>

=head1 DESCRIPTION

The container widget is a basic <div> element in markup notation. It also serves as a base for every other container-type widget.

=head1 CONSTRUCTOR

IWL::Container->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<E<lt>divE<gt>> markup would have.

=over 4

=item B<inline>

True if the type of the container is an inline container, false if 
it is a block container, default: false.

=item B<tag>

You can use a custom tag like I<h1>, I<pre>, or whatever you want.

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    if ($args{tag}) {
	$self->{_tag} = $args{tag};
    } else {
	if ($args{inline}) {
	    $self->{_tag} = "span";
	} else {
	    $self->{_tag} = "div";
	}
    }
    delete @args{qw(inline tag)};
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
