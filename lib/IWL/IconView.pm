#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::IconView;

use strict;

use base 'IWL::Widget';

use IWL::TreeModel;
use IWL::Container;
use IWL::Table::Container;
use IWL::Table::Row;
use IWL::String qw(randomize);
use IWL::JSON qw(toJSON);

use Locale::TextDomain qw(org.bloka.iwl);

use constant DEFAULT_COLUMNS => 3;

=head1 NAME

IWL::IconView - an iconbox widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::IconView>

=head1 DESCRIPTION

The IconView widget is similar to the L<IWL::Iconbox> widget, but uses a L<IWL::TreeModel> to represent its data

=head1 CONSTRUCTOR

IWL::IconView->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<model>

The L<IWL::TreeModel> for the IconView

=item B<columns>

The number of columns of icons. Defaults to I<3>

=item B<cellAttributes>

An array reference of cell attributes per column. See L<IWL::IconView::setCellAttributes|IWL::IconView/setCellAttributes>

=item B<textColumn>

The name/index of the column in the model, which will be used to display the text for an icon. The model column must be of type B<STRING>. A value of I<-1> will disable the text display

=item B<imageColumn>

The name/index of the column in the model, which will be used to display the image of the icon. The model column must be of type B<IMAGE>. A value of I<-1> will disable the image display

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new;

    $self->_init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setModel> (B<MODEL>)

Sets the model for the view

Parameter: B<MODEL> - an L<IWL::TreeModel>

=cut

sub setModel {
    my ($self, $model) = @_;

    $self->{_model}->remove if $self->{_model};
    $self->{_model} = $model;

    return $self;
}

=item B<getModel>

Returns the currently assigned model of the view

=cut

sub getModel {
    return shift->{_model};
}

=item B<setCellAttributes> (B<INDEX>, B<ATTRIBUTES>)

Sets the cell attributes for a particular cell index

Parameter: B<INDEX> - a cell index, B<ATTRIBUTES> - a hash reference of attributes, with the following possible keys:

=over 8

=item B<renderTemplate>

=item B<renderFunction>

A function which can manipulate the given cell for every node. It will receive the following parameters:

=over 12

=item B<cell>

The view cell for the particular node

=item B<type>

The data type for that cell

=item B<value>

The value of the cell

=item B<node>

The current node

=back

=item B<renderClass> (name => className, options => {})

I<renderFunction> and I<renderClass> are mutually exclusive. If a I<renderClass> is defined, it will be instantiated, and if it has a B<render> method, it will be used as a I<renderFunction>.

=back

=cut

sub setCellAttributes {
    my ($self, $index, $attr) = @_;
    return unless %$attr;

    $self->{_options}{cellAttributes}[$index] = $attr;

    return $self;
}

=item B<getCellAttributes> (B<INDEX>)

Sets the get attributes for a particular cell index

Parameter: B<INDEX> - a cell index

=cut

sub getCellAttributes {
    return shift->{_options}{cellAttributes}[shift];
}

=item B<setActive> (B<PATH>)

Sets the active item of the L<IWL::IconView>

Parameters: B<PATH> - the model path (or an index for flat models) for the item

=cut

sub setActive {
    my ($self, $path) = @_;
    $path = [$path] unless 'ARRAY' eq ref $path;
    $self->{_options}{initialPath} = $path;

    return $self;
}

=item B<getActive>

Returns the active item path

=cut

sub getActive {
    return shift->{_options}{initialPath};
}

=item B<setPageControlOptions> (B<URL>, [B<PARAMS>, B<OPTIONS>])

Sets the L<IWL::PageControl> bind settings, if the used model requires page control.

For parameter documentation, see L<IWL::PageControl::bindToWidget>

Returns a newly created IWL::PageControl with the given options. Users can place it manually, if the default location is not desired.

=cut

sub setPageControlOptions {
    my $self = shift;
    require IWL::PageControl;

    $self->{__pageControlEvent} = \@_;

    my $pager = IWL::PageControl->new();
    return $self->{__pager} = $pager;
}

=item B<setNodeSeparatorCallback> (B<CALLBACK>)

Sets the JavaScript callback which will determine whether a node is rendered as a separator

Parameters: B<CALLBACK> - the JavaScript function. It will receive the B<MODEL> and current B<NODE> as its two parameters. If it returns a true value, the node will be rendered as a separator.

=cut

sub setNodeSeparatorCallback {
    my ($self, $callback) = @_;

    $self->{_options}{nodeSeparatorCallback} = $callback;

    return $self;
}

# Protected
#
sub _setupDefaultClass {
    my $self = shift;

    $self->prependClass($self->{_defaultClass} . '_editable')
        if $self->{_options}{editable};
    $self->prependClass($self->{_defaultClass});
}

sub _realize {
    my $self    = shift;
    my $id      = $self->getId;

    return $self->_pushFatalError(__"No model was given!")
        unless $self->{_model};

    $self->SUPER::_realize;

    my $model = $self->{_model};
    if ($model->{options}{limit} && $model->isFlat && @{$self->{__pageControlEvent}}) {
        my $event = ref($self->{_model}) . "::refresh";
        $event =~ s/::/-/g;
        $self->{_options}{pageControlEventName} = $event;
        $self->{_model}->registerEvent($event, @{$self->{__pageControlEvent}});

        my $limit = $model->{options}{limit};
        $self->{__pager}->setPageOptions(
            pageCount => int(($model->{options}{totalCount} -1 ) / $limit) + 1,
            pageSize => $limit,
            page => int($model->{options}{offset} / $limit) + 1,
        );
        my $placed = !(!$self->{__pager}{parentNode});
        if ($placed) {
            $self->{_options}{placedPageControl} = 1;
        } else {
            $self->appendAfter($self->{__pager});
            $self->{__pager}->setStyle(position => 'absolute', left => '-1000px');
        }
        $self->{_options}{pageControl} = $self->{__pager}->getId;
    }

    foreach my $attrs (@{$self->{_options}{cellAttributes}}) {
        next unless 'HASH' eq ref $attrs;
        $attrs->{renderTemplate} = $attrs->{renderTemplate}->getContent
            if $attrs->{renderTemplate};
    }
    my $options = toJSON($self->{_options});

    $self->_appendInitScript("IWL.IconView.create('$id', @{[$model->toJSON]}, $options);");
}

sub _init {
    my ($self, %args) = @_;
    my $body          = IWL::Table::Container->new;

    $self->setAttributes(cellpadding => 0, cellspacing => 0);
    $self->appendChild($body);
    $self->{__body} = $body;

    $self->{_defaultClass} = 'iconview';
    $args{id} ||= randomize('iconview');

    $self->{_tag} = 'table';
    $self->{__pageControlEvent} = [];

    $self->{_options}{columns} = defined $args{columns} ? $args{columns} || DEFAULT_COLUMNS;

    $self->setModel($args{model}) if defined $args{model};

    if ('ARRAY' eq ref $args{cellAttributes}) {
        my $index = 0;
        $self->setCellAttributes($index++, $_)
            foreach @{$args{cellAttributes}};
    }

    delete @args{qw(columns cellAttributes model)};

    $self->requiredJs('base.js', 'model.js', 'treemodel.js', 'iconview.js');
    $self->_constructorArguments(%args);

    return $self;
}

addColumnType('IMAGE');

1;

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2008  Viktor Kojouharov. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
