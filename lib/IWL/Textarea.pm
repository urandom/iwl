#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Textarea;

use strict;

use base 'IWL::Input';

use IWL::Text;

=head1 NAME

IWL::Textarea - a text area widget

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Input -> IWL::Textarea

=head1 DESCRIPTION

The text area is a multi-line text entry.

=head1 CONSTRUCTOR

IWL::Textarea->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.
  readonly: set to true if the entry is read-only

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->{_tag} = "textarea";
    $self->{_noChildren} = 0;
    $self->setClass('textarea');

    if ($args{readonly}) {
        $self->setAttribute(readonly => 'true');
        delete $args{readonly};
    }
    $self->_constructorArguments(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setReadonly> (B<BOOL>)

Sets whether the type of the entry is read-only 

Parameter: B<BOOL> - a boolean value.

=cut

sub setReadonly {
    my ($self, $bool) = @_;

    if ($bool) {
        return $self->setAttribute(readonly => 'true');
    } else {
        return $self->deleteAttribute('readonly');
    }
}

=item B<setText> (B<TEXT>)

Sets the default text of the entry

Parameter: B<TEXT> - the text.

=cut

sub setText {
    my ($self, $text) = @_;

    my $text_obj = IWL::Text->new($text);

    return $self->setChild($text_obj);
}

=item B<extractState> (B<STATE>)

Update the IWL::Stash(3pm) B<STATE> according to the input state.

=cut

sub extractState {
    my ($self, $state) = @_;

    my $name = $self->getName;
    
    my $child = $self->child_nodes->[0] or return 1;
    my $value = $child->getContent;

    $state->pushValues($name => $value);

    return 1;
}

=item B<applyState> (B<STATE>)

Update the input element according to the IWL::Stash(3pm) B<STATE>
object.  The B<STATE> will get modified, i.e. the "used" element
will be shifted from the according slot (name attribute) of the
state.

=cut

sub applyState {
    my ($self, $state) = @_;

    my $name = $self->getName;
    my $value = $state->shiftValue($name);
    $value = '' unless defined $value;

    $self->setText($value);

    return 1;
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
