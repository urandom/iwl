#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Druid::Page;

use strict;

use base 'IWL::Container';

use IWL::String qw(randomize escape);
use IWL::JSON qw(toJSON);

=head1 NAME

IWL::Druid::Page - a page in a druid

=head1 INHERITANCE

L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container> -> L<IWL::Druid::Page>

=head1 DESCRIPTION

The druid page widget is a helper widget used by the IWL::Druid(3pm)

=head1 CONSTRUCTOR

IWL::Druid::Page->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=head1 SIGNALS

=over 4

=item B<select>

Fires when the page is selected

=item B<unselect>

Fires when the page is unselected

=item B<remove>

Fires when the page is removed

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setFinal> (B<BOOL>)

Makes the page the final one, thus changing the 'next' button to a 'finish'

=cut

sub setFinal {
    my ($self, $bool) = @_;

    if ($bool) {
	$self->setAttribute('iwl:druidFinalPage' => 1);
    } else {
	$self->deleteAttribute('iwl:druidFinalPage');
    }
    return $self;
}

=item B<isFinal>

Returns true if the page is the final page in the druid

=cut

sub isFinal {
    return shift->getAttribute('iwl:druidFinalPage', 1);
}

=item B<setSelected> (B<BOOL>)

Sets whether the page is the currently selected page

Parameters: B<BOOL> - true if the page should be the currently selected one

=cut

sub setSelected {
    my ($self, $bool) = @_;

    $self->{__selected} = $bool ? 1 : 0;
    return $self;
}

=item B<isSelected>

Returns true if the page is the currently selected one

=cut

sub isSelected {
    return shift->{__selected};
}

=item B<setCheckCB> (B<CALLBACK>, B<PARAM>, B<COLLECT>)

Sets the check callback for the page

Parameters: B<CALLBACK> - the function to be called when pressing the C<NEXT> button (if it returns true, the druid will proceed to the next page), B<PARAM> the parameter of the callback, B<COLLECT> - if true, collects all the control elements inside the page, and converts their names and values into a hash

=cut

sub setCheckCB {
    my ($self, $callback, $param, $collect) = @_;
    return unless $callback;
    $self->setAttribute('iwl:druidCheckCallback' => "$callback", 'none');
    if ($param) {
        $param = toJSON([$param, $collect ? 1 : 0]);
	$self->setAttribute('iwl:druidCheckParam' => $param, 'escape');
    }

    return $self;
}

# Protected
#
sub _registerEvent {
    my ($self, $event, $params, $options) = @_;

    if ($event eq 'IWL-Druid-Page-next') {
	$options->{method} = '_nextResponse';
    } elsif ($event eq 'IWL-Druid-Page-previous') {
	$options->{method} = '_previousResponse';
    } else {
	return $self->SUPER::_registerEvent($event, $params, $options);
    }

    return $options;
}

sub _previousEvent {
    __buttonEvent(@_);
}

sub _nextEvent {
    __buttonEvent(@_);
}

sub _setupDefaultClass {
    my $self = shift;
    my $index = 0;

    $self->prependClass($self->{_defaultClass} . '_selected') if $self->isSelected;
    $self->prependClass($self->{_defaultClass});
}

# Internal
#
sub __init {
    my ($self, %args) = @_;

    $self->{_defaultClass} = 'druid_page';
    $args{id} ||= randomize($self->{_defaultClass});

    $self->{_customSignals} = {select => [], unselect => [], remove => []};
    $self->{__selected} = 0;
    $self->_constructorArguments(%args);

    return $self;
}

sub __buttonEvent {
    my ($event, $handler) = @_;
    my ($list, $extras) = ('CODE' eq ref $handler)
      ? $handler->($event->{params}, $event->{options}{id}, $event->{options}{elementData})
      : (undef, undef);
    $list = [] unless ref $list eq 'ARRAY';
    my $html = escape(join('', map {$_->getContent} @$list));

    IWL::Object::printJSONHeader;
    print '{data: "' . $html . '", extras: '
      . (toJSON($extras) || 'null') . '}';
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
