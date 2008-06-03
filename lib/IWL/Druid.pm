#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Druid;

use strict;

use base 'IWL::Container';

use IWL::String qw(randomize escape);
use IWL::Button;
use IWL::Break;
use IWL::Druid::Page;

use Locale::TextDomain qw(org.bloka.iwl);

=head1 NAME

IWL::Druid - a sequential content widget.

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container> -> L<IWL::Druid>

=head1 DESCRIPTION

The Druid widget provides a way to navigate between sequential content via buttons.

=head1 CONSTRUCTOR

IWL::Druid->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=head1 SIGNALS

=over 4

=item B<current_page_change>

Fires when the current page of the druid has changed

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    # The list of pages
    $self->{__pages} = [];

    $self->_init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<appendPage> (B<OBJECT>, [B<CALLBACK>, B<PARAM>, B<CURRENT>])

Appends the data to the druid as a new page

Parameter: B<OBJECT> - the L<IWL::Object> to be appended, B<CALLBACK> - the function to be called when pressing the C<NEXT> button (if it returns true, the druid will proceed to the next page), B<PARAM> the parameter of the callback, B<CURRENT> - a boolean value which lets the appended page be the current one

Returns: the page

=cut

sub appendPage {
    my ($self, $object, $callback, $param, $current) = @_;
    return $self->__setupPage($object, $callback, $param, $current);
}

=item B<prependPage> (B<OBJECT>, [B<CALLBACK>, B<PARAM>, B<CURRENT>])

Prepends the data to the druid as a new page

Parameter: B<OBJECT> - the L<IWL::Object> to be prepended, B<CALLBACK> - the function to be called when pressing the C<NEXT> button (if it returns true, the druid will proceed to the next page), B<PARAM> the parameter of the callback, B<CURRENT> - a boolean value which lets the appended page be the current one

Returns: the page

=cut

sub prependPage {
    my ($self, $object, $callback, $param, $current) = @_;
    return $self->__setupPage($object, $callback, $param, $current, 1);
}

=item B<showFinish> (B<PAGE>)

Makes the current page the last one, thus changing the 'next' button to a 'finish' one

Parameters: B<PAGE> - a druid page

=cut

sub showFinish {
    my ($self, $page) = @_;
    $page->setFinal(1);
    return $self;
}

# Overrides
#
sub setId {
    my ($self, $id) = @_;

    $self->SUPER::setId($id);
    $self->{__content}->setId($id . '_content');
    $self->{__buttonContainer}->setId($id . '_button_container');
    $self->{__backButton}->setId($id . '_back_button');
    $self->{__nextButton}->setId($id . '_next_button');
    $self->{__okButton}->setId($id . '_ok_button');

    return $self;
}

# Protected
#
sub _realize {
    my $self     = shift;
    my $id       = $self->getId;
    my $selected = 0;

    $self->SUPER::_realize;
    foreach my $page (@{$self->{__pages}}) {
        last if $selected = $page->isSelected;
    }
    $self->{__pages}[0]->setSelected(1) if !$selected;
    $self->_appendInitScript("IWL.Druid.create('$id', '" . escape($self->{__finishText}) . "')");
}

sub _setupDefaultClass {
    my $self = shift;

    $self->SUPER::prependClass($self->{_defaultClass});
    $self->{__content}->prependClass($self->{_defaultClass} . '_content');
    $self->{__buttonContainer}->prependClass($self->{_defaultClass} . '_button_container');
    $self->{__backButton}->prependClass($self->{_defaultClass} . '_back_button');
    $self->{__nextButton}->prependClass($self->{_defaultClass} . '_next_button');
    $self->{__okButton}->prependClass($self->{_defaultClass} . '_ok_button');
    return $self;
}

sub _init {
    my ($self, %args) = @_;
    my $content     = IWL::Container->new;
    my $back_button =
      IWL::Button->newFromStock('IWL_STOCK_PREVIOUS', size => 'medium');
    my $next_button =
      IWL::Button->newFromStock('IWL_STOCK_NEXT', size => 'medium');
    my $ok_button =
      IWL::Button->newFromStock('IWL_STOCK_OK', size => 'medium', style => {visibility => 'hidden'});
    my $button_container = IWL::Container->new;
    my $span             = IWL::Break->new(style => {clear => 'both'});

    $self->{_defaultClass}     = 'druid';
    $self->{__content}         = $content;
    $self->{__backButton}      = $back_button;
    $self->{__nextButton}      = $next_button;
    $self->{__okButton}        = $ok_button;
    $self->{__buttonContainer} = $button_container;
    $self->{__finishText}      = $__->{'Finish'};
    $self->appendChild($content);
    $button_container->appendChild($ok_button);
    $button_container->appendChild($back_button);
    $button_container->appendChild($next_button);
    $self->appendChild($button_container);
    $self->appendChild($span);

    my $id = $args{id} || randomize($self->{_defaultClass});
    delete @args{qw(id)};
    $self->setId($id);

    $self->{_customSignals} = {current_page_change => []};
    $self->_constructorArguments(%args);
    $self->requiredJs('base.js', 'druid.js');

    return $self;
}

# Internal
#
sub __setupPage {
    my ($self, $data, $callback, $param, $selected, $reverse) = @_;
    my $page = IWL::Druid::Page->new;
    my $index;

    $page->appendChild($data);
    $page->setCheckCB($callback, $param);
    if ($reverse) {
        $index = unshift @{$self->{__pages}}, $page;
    } else {
        $index = push @{$self->{__pages}}, $page;
    }
    $page->setSelected($selected);

    if ($reverse) {
        $self->{__content}->prependChild($page);
    } else {
        $self->{__content}->appendChild($page);
    }

    return $page;
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
