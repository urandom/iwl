#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Accordion;

use strict;

use base 'IWL::Container';

use IWL::Accordion::Page;
use IWL::String qw(randomize);
use IWL::JSON qw(toJSON);

use Scalar::Util qw(weaken);

=head1 NAME

IWL::Accordion - an accordion widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container> -> L<IWL::Accordion>

=head1 DESCRIPTION

The accordion widget provided a way to stack content into an expandable container

=head1 CONSTRUCTOR

IWL::Accordion->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<horizontal>

True if the accordion should have a horizontal orientation. Note that a horizontal accordion must have a height style set

=item B<resizeSpeed>

The speed (I<0> - I<10>), at which the pages change. Set to I<11> have an instant change. Defaults to I<8>

=item B<eventActivation>

The event, which will trigger the page change. Example events are I<click>, I<mouseover>, I<mouseout>, ... Defaults to I<click>

=item B<defaultSize>

The default size of the accordion pages. A hashref with the optional keys I<width> and I<height>, and numeric values.

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    # The list of pages
    $self->{__pages} = [];

    $self->__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<appendPage> (B<TEXT>, [B<OBJECT>, B<SELECTED>])

Appends a new page and adds the object to the page

Parameter: B<OBJECT> - the L<IWL::Object> to be appended, B<TEXT> - the text for the page title, B<SELECTED> - true if the page should be the selected one

Returns: the newly created page

=cut

sub appendPage {
    my ($self, $text, $object, $selected) = @_;
    return $self->__setup_page($object, $text, $selected);
}

=item B<prependPage> (B<TEXT>, [B<OBJECT>, B<SELECTED>])

Prepends a new page and adds the object to the page

Parameter: B<OBJECT> - the L<IWL::Object> to be prepended, B<TEXT> - the text for the page title, B<SELECTED> - true if the page should be the selected one

Returns: the newly created page

=cut

sub prependPage {
    my ($self, $text, $object, $selected) = @_;
    return $self->__setup_page($object, $text, $selected, 1);
}

=item B<setOrientation> (B<ORIENTATION>)

Sets the orientation of the accordion

Parameters: B<ORIENTATION> - the orientation, can be either I<vertical> or I<horizontal>

Note: if the orientation is I<horizontal>, the accordion B<must> have a height style. Also, it is preferrable if some width is set through the L</setDefaultSize> method

=cut

sub setOrientation {
    my ($self, $orientation) = @_;
    return unless $orientation eq 'vertical' || $orientation eq 'horizontal';

    $self->{_options}{direction} = $orientation;
    return $self;
}

=item B<getOrientation>

Returns the orientation of the accordion

=cut

sub getOrientation {
    return shift->{_options}{direction};
}

=item B<setResizeSpeed> (B<SPEED>)

Sets the resize speed of the accordion

Parameters: B<SPEED> - the resize speed, between I<0> and I<10>, and I<11> for instant

=cut

sub setResizeSpeed {
    my ($self, $speed) = @_;
    return unless $speed =~ /^\d+$/;

    $self->{_options}{resizeSpeed} = $speed;
    return $self;
}

=item B<getResizeSpeed>

Returns the resize speed of the accordion

=cut

sub getResizeSpeed {
    return shift->{_options}{resizeSpeed};
}

=item B<setEventActivation> (B<EVENT>)

Sets the event, which will trigger the page change.

Parameters: B<EVENT> - the event, which will trigger the page change. Example events are I<click>, I<mouseover>, I<mouseout>, .... Defaults to I<click>

=cut

sub setEventActivation {
    my ($self, $event) = @_;

    $self->{_options}{onEvent} = $event;
    return $self;
}

=item B<getEventActivation>

Returns the event, which will trigger the page change

=cut

sub getEventActivation {
    return shift->{_options}{onEvent};
}

=item B<setDefaultSize> (B<%SIZE>)

Sets the default size of the accordion pages

Parameters: B<%SIZE> - the size hash, with optional I<width> and I<height> keys, and numeric values, representing the size in pixels

=cut

sub setDefaultSize {
    my ($self, %size) = @_;

    $self->{_options}{defaultSize} = \%size;
    return $self;
}

=item B<getDefaultSize>

Returns the default size of the accordion pages

=cut

sub getDefaultSize {
    return %{shift->{_options}{defaultSize}};
}

# Protected
#
sub _realize {
    my $self     = shift;
    my $id       = $self->getId;
    my @pages    = @{$self->{__pages}};
    my $selected = 0;

    $self->SUPER::_realize;
    for (my $i = 0, my $page = $pages[0]; $i < @pages; $page = $pages[++$i]) {
        $selected = $i and last if $page->isSelected;
    }
    my $page_id = $pages[$selected]->getId;

    $self->{_options}{classNames} = {
	toggle       => $self->{_defaultClass} . '_page_title_' . $self->{_options}{direction},
	toggleActive => $self->{_defaultClass} . '_page_title_selected',
	content      => $self->{_defaultClass} . '_page_content'
    };
    my $options  = toJSON($self->{_options});
    my $script = <<EOF;
var accordion_widget = \$('$id');
accordion_widget.control = new accordion('#$id', $options);
accordion_widget.control.activate(\$('$page_id'));
EOF
    $self->_appendInitScript($script);
}

sub _setupDefaultClass {
    my $self = shift;

    $self->SUPER::prependClass($self->{_defaultClass} . '_' . $self->getOrientation);
    $self->SUPER::prependClass($self->{_defaultClass});
}

# Internal
#
sub __init {
    my ($self, %args) = @_;

    $self->{_defaultClass} = 'accordion';
    $args{id} = randomize($self->{_defaultClass}) if !$args{id};

    $self->{_options} = {direction => 'vertical', resizeSpeed => 8, onEvent => 'click',
	defaultSize => {width => undef, height => undef}};

    $self->{_options}{direction} = 'horizontal' if $args{horizontal};
    $self->{_options}{onEvent} = $args{eventActivation} if $args{eventActivation};
    $self->{_options}{resizeSpeed} = $args{resizeSpeed} if $args{resizeSpeed}
      && $args{resizeSpeed} =~ /^\d+$/;
    delete @args{qw(horizontal resizeSpeed)};

    $self->_constructorArguments(%args);
    $self->requiredJs('base.js', 'dist/accordion.js');

    return $self;
}

sub __setup_page {
    my ($self, $object, $text, $selected, $reverse) = @_;
    my $page = IWL::Accordion::Page->new;

    $page->appendContent($object);
    if ($reverse) {
	unshift @{$self->{__pages}}, $page;
    } else {
	push @{$self->{__pages}}, $page;
    }

    $page->setSelected($selected) if $object;
    $page->setTitle($text);

    if ($reverse) {
	$self->prependChild($page);
    } else {
	$self->appendChild($page);
    }

    weaken($page->{_accordion} = $self);
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
