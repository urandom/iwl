#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Combo::Option;

use strict;

use base 'IWL::Widget';

use IWL::Text;

=head1 NAME

IWL::Combo::Option - an option widget for the combobox

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Combo::Option>

=head1 DESCRIPTION

The Option widget provides a wrapper for the B<<option>> markup tag.

=head1 CONSTRUCTOR

IWL::Combo::Option->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<<option>> markup would have.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);

    $self->{_tag}        = "option";
    $self->{_noChildren} = 0;

    return $self;
}

=head1 METHODS

=over 4

=item B<setText> (B<TEXT>)

Sets the text of the option.

Parameters: B<TEXT> - the text to be added

=cut

sub setText {
    my ($self, $text) = @_;
    my $label = IWL::Text->new($text);

    return $self->setChild($label);
}

=item B<getText>

Returns the text of the option

=cut

sub getText {
    my $self = shift;
    return $self->{childNodes}[0] ? $self->{childNodes}[0]->getContent : '';
}

=item B<setSelected> (B<BOOL>)

Sets whether the option us selected.

Parameters: B<BOOL> - true if the option is selected

=cut

sub setSelected {
    my ($self, $bool) = @_;

    if ($bool) {
	$self->setAttribute(selected => 'selected');
    } else {
	$self->deleteAttribute('selected');
    }
    return $self;
}

=item B<isSelected>

Returns true if the option is selected, false otherwise.

=cut

sub isSelected {
    my ($self) = @_;

    my $selected = $self->getAttribute('selected', 1);

    return !(!$selected);
}

=item B<setValue>

Sets the value attribute of the option

=cut

sub setValue {
    my ($self, $value) = @_;

    return $self->setAttribute(value => $value);
}

=item B<getValue>

Gets the value attribute of the option.

=cut

sub getValue {
    shift->getAttribute('value', 1);
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
