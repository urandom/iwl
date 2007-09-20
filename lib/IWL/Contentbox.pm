#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Contentbox;

use strict;

use base 'IWL::Container';

use IWL::Config qw(%IWLConfig);
use IWL::String qw(randomize);
use IWL::Label;
use IWL::Image;
use IWL::Script;

use Locale::TextDomain qw(org.bloka.iwl);
use JSON;

use constant TYPE => {
    none     => 1,
    drag     => 1,
    resize   => 1,
    dialog   => 1,
    window   => 1,
    noresize => 1,
};

=head1 NAME

IWL::Contentbox - a content box

=head1 INHERITANCE

L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container> -> L<IWL::Contentbox>

=head1 DESCRIPTION

The Contentbox is a box, which resembles a window, with a title, a header, a footer, and a central place for content.

=head1 CONSTRUCTOR

IWL::Contentbox->new ([B<%ARGS>])

=over 4

=item B<autoWidth>

Makes the content box as wide as the content. Turns off resizing

=item B<shadows>

Enable shadow classes

=item B<modal>

Make the window a modal window

=item B<closeModalOnClick>

Makes the window close when the user clicks outside of it

=back

=head1 SIGNALS

=over 4

=item B<close>

Fires when the contentbox has closed

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

=item B<appendTitle> (B<WIDGET>)

Sets the title of the content box.

Parameters: B<WIDGET> - the widget of type IWL::Widget(3pm) with which to fill the title

=cut

sub appendTitle {
    my ($self, $widget) = @_;

    $self->{__titler}->appendChild($widget);
    return $self;
}

=item B<appendTitleText> (B<TEXT>)

Sets the title of the content box.

Parameters: B<TEXT> - the text to be append as the title

=cut

sub appendTitleText {
    my ($self, $text) = @_;

    if (!$self->{__titleLabel}) {
	$self->{__titleLabel} = IWL::Label->new;
	$self->{__titler}->appendChild($self->{__titleLabel});
    }
    $self->{__titleLabel}->appendText($text);
    return $self;
}

=item B<appendHeader> (B<WIDGET>)

Sets the header of the content box.

Parameters: B<WIDGET> - the widget of type IWL::Widget(3pm) with which to fill the header 

=cut

sub appendHeader {
    my ($self, @widget) = @_;

    foreach my $widget (@widget) {
        $self->{__header}->appendChild($widget);
    }
    $self->{__header}{_ignore} = 0;
    return $self;
}

=item B<appendHeaderText> (B<TEXT>)

Sets the header of the content box.

Parameters: B<TEXT> - the text to be append as the header

=cut

sub appendHeaderText {
    my ($self, $text) = @_;

    my $label = IWL::Label->new;
    $label->setText($text);

    $self->{__header}{_ignore} = 0;
    $self->{__header}->appendChild($label);
    return $self;
}

=item B<appendContent> (B<WIDGET>)

Sets the content of the content box.

Parameters: B<WIDGET> - the widget of type IWL::Widget(3pm) with which to fill the content

=cut

sub appendContent {
    my ($self, @widget) = @_;

    foreach my $widget (@widget) {
        $self->{__content}->appendChild($widget);
    }
    return $self;
}

=item B<appendContentText> (B<TEXT>)

Sets the content of the content box.

Parameters: B<TEXT> - the text to be append as the content

=cut

sub appendContentText {
    my ($self, $text) = @_;
    my $label = IWL::Label->new;

    $label->setText($text);

    $self->{__content}->appendChild($label);
    return $self;
}

=item B<appendFooter> (B<WIDGET>)

Sets the footer of the content box.

Parameters: B<WIDGET> - the widget of type IWL::Widget(3pm) with which to fill the footer 

=cut

sub appendFooter {
    my ($self, @widget) = @_;

    foreach my $widget (@widget) {
        $self->{__footerr}->appendChild($widget);
    }
    $self->{__footer}{_ignore} = 0;
    return $self;
}

=item B<appendFooterText> (B<TEXT>)

Sets the footer of the content box.

Parameters: B<TEXT> - the text to be append as the footer 

=cut

sub appendFooterText {
    my ($self, $text) = @_;
    my $label = IWL::Label->new;

    $label->setText($text);

    $self->{__footer}{_ignore} = 0;
    $self->{__footerr}->appendChild($label);
    return $self;
}

=item B<setType> (B<TYPE>)

Sets the type of the content box

Parameters: B<TYPE> - the type of the content box

=over 8

=item B<none>

Default, no type

=item B<drag>

Draggable

=item B<resize>

Resizable

=item B<dialog>

Draggable & resizable

=item B<window>

Dialog + close button

=item B<noresize>

Window without resizing

=back

=cut 

sub setType {
    my ($self, $type) = @_;

    return if !exists TYPE->{$type};

    $self->{_options}{type} = $type;
    return $self;
}

=item B<setHeaderColorType> (B<INDEX>)

Sets the color type of the header to a predefined value.

Parameters: B<INDEX> - the index of the color type, which is defined in the stylesheets

=cut

sub setHeaderColorType {
    my ($self, $index) = @_;

    $self->{__headerColorIndex} = $index;
    return $self;
}

=item B<setFooterColorType> (B<INDEX>)

Sets the color type of the footer to a predefined value.

Parameters: B<INDEX> - the index of the color type, which is defined in the stylesheets

=cut

sub setFooterColorType {
    my ($self, $index) = @_;

    $self->{__footerColorIndex} = $index;
    return $self;
}

=item B<setShadows> (B<BOOL>)

Enables shadows under the contentbox. Effectively, only changes the class of the contentbox, so it is wise to B<not> change the class if you are going to use this.

Parameters: B<BOOL> - boolean value, true if the contentbox should have shadows

=cut

sub setShadows {
    my ($self, $bool) = @_;
    
    if ($bool) {
	$self->{_options}{hasShadows} = 'true';
    } else {
	$self->{_options}{hasShadows} = 'false';
    }
    return $self;
}

=item B<setAutoWidth> (B<BOOL>)

Sets whether the contentbox will try to fit itself to the size of it's content

Parameters: B<BOOL> - true if the contentbox should try to set it's width according to it's content

=cut

sub setAutoWidth {
    my ($self, $bool) = @_;

    if ($bool) {
	$self->{_options}{auto} = 'true';
    } else {
	$self->{_options}{auto} = 'false';
    }

    return $self;
}

=item B<setTitleImage> (B<IMAGE>)

Sets the image located in the title block of the contentbox

Parameters: B<IMAGE> - an IWL::Image(3) image widget

=cut

sub setTitleImage {
    my ($self, $image) = @_;

    $self->{__titleImage} = $image || undef;
    return $self;
}

# Overrides
#
sub setId {
    my ($self, $id) = @_;

    $self->SUPER::setId($id);
    $self->{__top}->setId($id . "_top");
    $self->{__topr}->setId($id . "_topr");
    $self->{__title}->setId($id . "_title");
    $self->{__titler}->setId($id . "_titler");
    $self->{__header}->setId($id . "_header");
    $self->{__middle}->setId($id . "_middle");
    $self->{__middler}->setId($id . "_middler");
    $self->{__content}->setId($id . "_content");
    $self->{__footer}->setId($id . "_footer");
    $self->{__footerr}->setId($id . "_footerr");
    $self->{__bottom}->setId($id . "_bottom");
    $self->{__bottomr}->setId($id . "_bottomr");

    $self->{__titleImage}->setId($id . "_title_image") if $self->{__titleImage};
    $self->{__titleLabel}->setId($id . "_title_label") if $self->{__titleLabel};

    return $self;
}

# Protected
#
sub _realize {
    my $self = shift;
    my $options = objToJson($self->{_options});
    my $id = $self->getId;
    $self->prependClass('shadowbox') if $self->{_options}{hasShadows} eq 'true';
    $self->SUPER::_realize;
    $self->{__titler}->prependChild($self->{__titleImage});
    $self->__set_type;
    $self->{__init}->setScript("Contentbox.create('$id', $options);");
}

sub _setupDefaultClass {
    my ($self) = @_;

    $self->SUPER::prependClass($self->{_defaultClass});
    $self->{__top}->prependClass($self->{_defaultClass} . "_top");
    $self->{__topr}->prependClass($self->{_defaultClass} . "_topr");
    $self->{__title}->prependClass($self->{_defaultClass} . "_title");
    $self->{__titler}->prependClass($self->{_defaultClass} . "_titler");
    $self->{__middle}->prependClass($self->{_defaultClass} . "_middle");
    $self->{__middler}->prependClass($self->{_defaultClass} . "_middler");
    $self->{__content}->prependClass($self->{_defaultClass} . "_content");
    $self->{__titleImage}->prependClass($self->{_defaultClass} . "_title_image") if $self->{__titleImage};
    $self->{__titleLabel}->prependClass($self->{_defaultClass} . "_title_label") if $self->{__titleLabel};

    my $hindex = $self->{__headerColorIndex};
    my $findex = $self->{__footerColorIndex};
    if ($hindex) {
	$self->{__header}->prependClass($self->{_defaultClass} . "_header_alt" . $hindex);
    }
    if ($findex) {
	$self->{__footer}->prependClass($self->{_defaultClass} . "_footer_alt" . $findex);
	$self->{__footerr}->prependClass($self->{_defaultClass} . "_footerr_alt" . $findex);
	$self->{__bottom}->prependClass($self->{_defaultClass} . "_bottom_alt" . $findex);
	$self->{__bottomr}->prependClass($self->{_defaultClass} . "_bottomr_alt" . $findex);
    }

    $self->{__header}->prependClass($self->{_defaultClass} . "_header");
    $self->{__footer}->prependClass($self->{_defaultClass} . "_footer");
    $self->{__footerr}->prependClass($self->{_defaultClass} . "_footerr");
    $self->{__bottom}->prependClass($self->{_defaultClass} . "_bottom");
    $self->{__bottomr}->prependClass($self->{_defaultClass} . "_bottomr");

    return $self;
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $top     = IWL::Container->new;
    my $topr    = IWL::Container->new;
    my $title   = IWL::Container->new;
    my $titler  = IWL::Container->new;
    my $header  = IWL::Container->new;
    my $middle  = IWL::Container->new;
    my $middler = IWL::Container->new;
    my $content = IWL::Container->new;
    my $footer  = IWL::Container->new;
    my $footerr = IWL::Container->new;
    my $bottom  = IWL::Container->new;
    my $bottomr = IWL::Container->new;

    $self->{_defaultClass} = 'contentbox';
    $self->{_options} = {auto => 'false', modal => 'false'};

    $self->{__top}     = $top;
    $self->{__topr}    = $topr;
    $self->{__title}   = $title;
    $self->{__titler}  = $titler;
    $self->{__titleImage} = IWL::Image->new(src => $IWLConfig{IMAGE_DIR} . "/contentbox/arrow_right.gif", alt => 'Title Icon');
    $self->{__header}  = $header;
    $self->{__middle}  = $middle;
    $self->{__middler} = $middler;
    $self->{__content} = $content;
    $self->{__footer}  = $footer;
    $self->{__footerr} = $footerr;
    $self->{__bottom}  = $bottom;
    $self->{__bottomr} = $bottomr;
    $self->appendChild($top);
    $top->appendChild($topr);
    $self->appendChild($title);
    $title->appendChild($titler);
    $self->appendChild($header);
    $self->appendChild($middle);
    $middle->appendChild($middler);
    $middler->appendChild($content);
    $self->appendChild($footer);
    $footer->appendChild($footerr);
    $self->appendChild($bottom);
    $bottom->appendChild($bottomr);

    $header->{_ignore} = 1;
    $footer->{_ignore} = 1;

    if ($args{autoWidth}) {
	$self->{_options}{auto} = 'true';
    }
    if ($args{modal}) {
	$self->{_options}{modal} = 'true';
	if ($args{closeModalOnClick}) {
	    $self->{_options}{closeModalOnClick} = 'true';
	}
    }

    my $id = $args{id} ? $args{id} : randomize($self->{_defaultClass});
    $self->setId($id);

    if ($args{shadows}) {
	$self->setShadows(1);
    } else {
	$self->setShadows(0);
    }
    delete @args{qw(id autoWidth modal closeModalOnClick shadows)};

    $self->{__init} = IWL::Script->new;
    $self->setType('none');

    $self->{__headerColorIndex} = 0;
    $self->{__footerColorIndex} = 0;

    $self->_appendAfter($self->{__init});
    $self->_constructorArguments(%args);
    $self->requiredJs('base.js', 'dist/dragdrop.js', 'resizer.js', 'contentbox.js');
    $self->{_customSignals} = {close => []};

    # Callbacks
    return $self;
}

sub __set_type {
    my ($self) = @_;
    my $type = $self->{_options}{type};

    return unless $self->getId;
    return unless $type;

    if ($type eq 'drag' || $type eq 'dialog' || $type eq 'window' || $type eq 'noresize') {
	$self->__add_move;
    }
    return $self;
}

sub __add_move {
    my ($self) = @_;
    $self->{__title}->setStyle(cursor  => 'move');
    $self->{__titler}->setStyle(cursor => 'move');
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
