#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Druid;

use strict;

use base 'IWL::Container';

use IWL::Label;
use IWL::String qw(randomize);

use JSON;
use Locale::TextDomain qw(org.bloka.iwl);

=head1 NAME

IWL::Druid - a sequential content widget.

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Container -> IWL::Druid

=head1 DESCRIPTION

The Druid widget provides a way to navigate between sequential content via buttons.

=head1 CONSTRUCTOR

IWL::Druid->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->{_noChildren} = 0;

    # The list of pages
    $self->{__pages} = [];

    # Current page index
    $self->{__current} = 0;

    $self->__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<appendPage> (B<OBJECT>, [B<CALLBACK>, B<PARAM>, B<CURRENT>])

Appends the data to the druid as a new page

Parameter: B<OBJECT> - the IWL::Object(3pm) to be appended, B<CALLBACK> - the function to be called when pressing the C<NEXT> button (if it returns true, the druid will proceed to the next page), B<PARAM> the parameter of the callback, B<CURRENT> - a boolean value which lets the appended page be the current one

Returns: the page

=cut

sub appendPage {
    my ($self, $object, $callback, $param, $current) = @_;
    return $self->__setup_page($object, $callback, $param, $current);
}

=item B<prependPage> (B<OBJECT>, [B<CALLBACK>, B<PARAM>, B<CURRENT>])

Prepends the data to the druid as a new page

Parameter: B<OBJECT> - the IWL::Object(3pm) to be prepended, B<CALLBACK> - the function to be called when pressing the C<NEXT> button (if it returns true, the druid will proceed to the next page), B<PARAM> the parameter of the callback, B<CURRENT> - a boolean value which lets the appended page be the current one

Returns: the page

=cut

sub prependPage {
    my ($self, $object, $callback, $param, $current) = @_;
    return $self->__setup_page($object, $callback, $param, $current, 1);
}

=item B<showFinish> (B<PAGE>)

Makes the current page the last one, thus changing the 'next' button to a 'finish' one

Parameters: B<PAGE> - a druid page

=cut

sub showFinish {
    my ($self, $page) = @_;
    return $page->setAttribute('iwl:druidLastPage' => 1);
}

# Overrides
#
sub setId {
    my ($self, $id) = @_;

    $self->SUPER::setId($id);
    $self->{__content}->setId($id . '_content');
    $self->{__backButton}->setId($id . '_back_button');
    $self->{__nextButton}->setId($id . '_next_button');

    for (my $i = 0; $i < @{$self->{__pages}}; $i++) {
        $self->{__pages}[$i]->setId($id . '_page_' . $i);
    }
    return $self;
}

# Protected
#
sub _realize {
    my $self = shift;
    my $id = $self->getId;

    $self->SUPER::_realize;
    $self->{__init}->setScript("Druid.create('$id', '$self->{__finishText}')");
}

sub _setupDefaultClass {
    my $self = shift;
    my $index = 0;

    $self->SUPER::prependClass($self->{_defaultClass});
    $self->{__content}->prependClass($self->{_defaultClass} . '_content');

    foreach my $page (@{$self->{__pages}}) {
	if ($self->{__current} == $index++) {
	    $page->prependClass($self->{_defaultClass} . '_page_selected');
	}
        $page->prependClass($self->{_defaultClass} . '_page');
    }
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $content     = IWL::Container->new;
    my $back_button =
      IWL::Button->newFromStock('IWL_STOCK_BACK', size => 'medium');
    my $next_button =
      IWL::Button->newFromStock('IWL_STOCK_NEXT', size => 'medium');
    my $button_container = IWL::Container->new(class => $args{id} . '_button_container');
    my $init = IWL::Script->new;
    my $span = IWL::Break->new(style => {clear => 'both'});

    $self->{_defaultClass} = 'druid';
    $self->{__content}     = $content;
    $self->{__backButton}  = $back_button;
    $self->{__nextButton}  = $next_button;
    $self->{__init}        = $init;
    $self->{__finishText}  = $__->{'Finish'};
    $self->appendChild($content);
    $button_container->appendChild($back_button);
    $button_container->appendChild($next_button);
    $self->appendChild($button_container);
    $self->appendChild($span);
    $self->appendChild($init);

    my $id = $args{id} || randomize($self->{_defaultClass});
    delete @args{qw(id)};
    $self->setId($id);

    $self->{_customSignals} = {current_page_change => []};
    $self->_constructorArguments(%args);
    $self->requiredJs('base.js', 'druid.js');

    return $self;
}

sub __setup_page {
    my ($self, $data, $callback, $param, $current, $reverse) = @_;
    my $page = IWL::Container->new;
    my $index;

    $page->{_customSignals} = {select => [], unselect => [], remove => []};
    $page->appendChild($data);
    if ($callback) {
	my $param = objToJson([$param]) if $param;
        $param ||= 'null';
        $page->setAttribute('iwl:druidCheckCallback' => "$callback", 'none');
        $page->setAttribute('iwl:druidCheckParam' => "$param", 'uri') if $param;
    }
    if ($reverse) {
        $index = unshift @{$self->{__pages}}, $page;
    } else {
        $index = push @{$self->{__pages}}, $page;
    }
    $index--;
    $self->{__current} = $index if $current;

    if ($reverse) {
        $self->{__content}->prependChild($page);
    } else {
        $self->{__content}->appendChild($page);
    }

    $self->setId($self->getId);
    return $page;
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
