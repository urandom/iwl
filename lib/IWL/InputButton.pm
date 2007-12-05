#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::InputButton;

use strict;

use base 'IWL::Input';

use IWL::String qw(randomize);

=head1 NAME

IWL::InputButton - a input button

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Input> -> L<IWL::InputButton>

=head1 DESCRIPTION

The InputButton provides a regular input of type button

=head1 CONSTRUCTOR

IWL::InputButton->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<submit>

Set to true if the input should be of type 'submit'

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new;

    $self->__init(%args);
    return $self;
}

=head1 METHODS

=over 4

=item B<setLabel> (B<TEXT>)

Sets the text of the label for the button. This is an alias to the setValue method.

Parameter: B<TEXT> - the text.

=cut

sub setLabel {
    my ($self, $text) = @_;

    return $self->setValue($text);
}

=item B<getLabel>

Returns the label of the button

=cut

sub getLabel {
    return shift->getValue;
}

# Internal
#
sub __init {
    my ($self, %args) = @_;

    $self->{_defaultClass} = 'inputbutton';
    $args{id} = randomize($self->{_defaultClass}) if !$args{id};
    my $type  = $args{submit} ? 'submit' : 'button';
    delete @args{qw(submit)};

    $self->setAttribute(type => $type);
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
