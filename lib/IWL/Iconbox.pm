#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Iconbox;

use strict;

use IWL::Script;
use IWL::Response;
use IWL::String qw(randomize escape);
use IWL::JSON qw(toJSON);

use base qw(IWL::Container);

use Locale::TextDomain qw(org.bloka.iwl);
use Scalar::Util qw(weaken);

=head1 NAME

IWL::Iconbox - an iconbox widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container> -> L<IWL::Iconbox>

=head1 DESCRIPTION

The iconbox widget provides a container that holds icons.

=head1 CONSTRUCTOR

IWL::Iconbox->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-value options. These include:

=over 4

=item B<width>

Width of the iconbox without the borders

=item B<height>

Height of the iconbox without the borders

=item B<multipleSelect>

True if the iconbox should be able to select multiple icons

=back

=head1 SIGNALS

=over 4

=item B<select_all>

Fires when all the icons have been selected

=item B<unselect_all>

Fires when all the icons have been unselected

=item B<load>

Fires when the iconbox and its icons have finished loading

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->{__iconNum} = 0;
    $self->__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<appendIcon> (B<ICON>)

Appends an icon object to the iconbox.

Parameters: B<ICON> - the IWL::Iconbox::Icon object to be appended

=cut

sub appendIcon {
    my ($self, $icon) = @_;
    $self->{__iconCon}->appendChild($icon);
    $icon->{_iconbox} = $self and weaken $icon->{_iconbox};
    push @{$self->{__icons}}, $icon;
    return $icon;
}

=item B<prependIcon> (B<ICON>)

Prepend an icon object to the iconbox.

Parameters: B<ICON> - the IWL::Iconbox::Icon object to be prepended

=cut

sub prependIcon {
    my ($self, $icon) = @_;
    $self->{__iconCon}->prependChild($icon);
    $icon->{_iconbox} = $self and weaken $icon->{_iconbox};;
    unshift @{$self->{__icons}}, $icon;
    return $icon;
}

# Overrides
#
sub setId {
    my ($self, $id) = @_;

    $self->SUPER::setId($id);
    $self->{__iconCon}->setId($id . "_icon_container");
    $self->{__statusLabel}->setId($id . "_status_label")
      if $self->{__statusLabel};
    return $self;
}

# Protected
#
sub _realize {
    my $self    = shift;
    my $id      = $self->getId;
    my $options = toJSON($self->{_options});
    my $script;

    # TRANSLATORS: {TITLE} is a placeholder
    my $delete  = escape(__"The icon '{TITLE}' was removed.");

    $self->SUPER::_realize;

    $script = "IWL.Iconbox.create('$id', $options, {'delete': '$delete'});";
    foreach my $icon (@{$self->{__icons}}) {
	my $icon_id = $icon->getId;
        $script .= "\$('$id').selectIcon('$icon_id');" if $icon->{_selected};
    }
    $self->_appendInitScript($script);
}

sub _setupDefaultClass {
    my ($self) = @_;

    $self->SUPER::prependClass($self->{_defaultClass});
    $self->{__iconCon}->prependClass($self->{_defaultClass} . "_icon_container");
    $self->{__statusLabel}->prependClass($self->{_defaultClass} . "_status_label")
      if $self->{__statusLabel};
    foreach my $icon (@{$self->{__icons}}) {
	$icon->prependClass($self->{_defaultClass} . '_icon') unless $icon->getClass;
    }
    return $self;
}

sub _registerEvent {
    my ($self, $event, $params, $options) = @_;

    if ($event eq 'IWL-Iconbox-refresh') {
	$options->{method} = '_refreshResponse';
    } else {
	return $self->SUPER::_registerEvent($event, $params, $options);
    }

    return $options;
}

sub _refreshEvent {
    my ($event, $handler) = @_;
    my $response = IWL::Response->new;

    my ($list, $extras) = ('CODE' eq ref $handler)
      ? $handler->($event->{params})
      : (undef, undef);
    $list = [] unless ref $list eq 'ARRAY';

    $response->send(
        content => '{icons: ['
          . join(',', map {'"' . escape($_->getContent) . '"'} @$list)
          . '], extras: ' . (toJSON($extras) || 'null'). '}',
        header => IWL::Object::getJSONHeader
      );
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $icon_con = IWL::Container->new;

    $self->{_selected}     = IWL::Script->new;
    $self->{__iconCon}     = $icon_con;
    $self->{__icons}       = [];
    $self->{_defaultClass} = 'iconbox';

    $self->{_options} = {multipleSelect => 0, clickToSelect => 0};
    $self->{_options}{multipleSelect} = 1 if $args{multipleSelect};
    $self->{_options}{clickToSelect}  = 1 if $args{clickToSelect};
    $self->appendChild($icon_con);
    if (!$args{withoutStatusBar}) {
        my $status_label = IWL::Container->new;

        $self->{__statusLabel} = $status_label;
        $self->appendChild($status_label);
    }

    $args{id} = randomize($self->{_defaultClass}) if !$args{id};
    delete @args{qw(multipleSelect clickToSelect withoutStatusBar)};

    $self->setStyle(width        => $args{width})  if $args{width};
    $icon_con->setStyle(height   => $args{height}) if $args{height};
    $icon_con->setStyle(overflow => 'auto');

    $self->{_customSignals} =
      {select_all => [], unselect_all => [], load => []};
    $self->_constructorArguments(%args);
    $self->requiredJs('base.js', 'iconbox.js');
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
