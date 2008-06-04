#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Page::Meta;

use strict;

use base 'IWL::Object';

=head1 NAME

IWL::Page::Meta - a meta object

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Page::Meta>

=head1 DESCRIPTION

The meta object provides the B<<meta>> html markup, with all it's attributes.

=head1 CONSTRUCTOR

IWL::Meta->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<<meta>> markup would have.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);

    $self->{_tag}  = "meta";
    $self->{_noChildren} = 1;
    $self->setAttribute($_ => $args{$_}) foreach (keys %args);

    return $self;
}

=head1 METHODS

=over 4

=item B<set> (B<EQUIV>, B<CONTENT>)

Sets the http-equiv to B<EQUIV> and the content to B<CONTENT>

Parameters: B<EQUIV> - the http-equiv. B<CONTENT> - the content

=cut

sub set {
    my ($self, $equiv, $content) = @_;

    $self->setAttribute("http-equiv" => $equiv);
    return $self->setAttribute(content => $content);
}

=item B<get>

Returns an array of the meta object's I<http-equiv> and I<content> values

=cut

sub get {
    my $self = shift;
    return $self->getAttribute('http-equiv', 1), $self->getAttribute('content', 1);
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
