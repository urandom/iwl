#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::IconView;

use strict;

use base 'IWL::Container';

use IWL::ListModel;
use IWL::Container;
use IWL::String qw(randomize);
use IWL::JSON qw(toJSON);

use Locale::TextDomain qw(org.bloka.iwl);

use constant Orientation => {
    HORIZONTAL => 0,
    VERTICAL => 1,
};

use constant CellType => {
    TEXT => 0,
    IMAGE => 1,
};

my $default_columns = 5;

=head1 NAME

IWL::IconView - an iconbox widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::IconView>

=head1 DESCRIPTION

The IconView widget is similar to the L<IWL::Iconbox> widget, but uses a L<IWL::ListModel> to represent its data

=head1 CONSTRUCTOR

IWL::IconView->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<model>

The L<IWL::ListModel> for the IconView

=item B<columns>

The number of columns of icons

=item B<columnWidth>

The width of the columns, in pixels. If neither B<columns> nor B<columnWidth> is specified, B<columns> assumes a default value of I<5>

=item B<cellAttributes>

An array reference of cell attributes per column. See L<IWL::IconView::setCellAttributes|IWL::IconView/setCellAttributes>

=item B<textColumn>

The name/index of the column in the model, which will be used to display the text for an icon. The model column must be of type B<STRING>. A value of I<-1> will disable the text display

=item B<imageColumn>

The name/index of the column in the model, which will be used to display the image of the icon. The model column must be of type B<IMAGE>. A value of I<-1> will disable the image display

=item B<orientation>

Sets the orientation of the icons. With B<IWL::IconView::Orientation-E<gt>{VERTICAL}> (I<default>), the label will appear below the image. With B<IWL::IconView::Orientation-E<gt>{HORIZONTAL}>, the label will appear beside the image.

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

Parameter: B<MODEL> - an L<IWL::ListModel>

=cut

sub setModel {
    my ($self, $model) = @_;

    $self->unrequire($self->{_model}->getRequiredResources)
        if $self->{_model};

    if ($model) {
        $self->{_model} = $model;
        $self->require($model->getRequiredResources);
    }

    return $self;
}

=item B<getModel>

Returns the currently assigned model of the view

=cut

sub getModel {
    return shift->{_model};
}

=item B<setCellAttributes> (B<TYPE>, B<ATTRIBUTES>)

Sets the cell attributes for a particular cell index

Parameter: B<TYPE> - the cell type, can be one of:

=over 8

=item B<IWL::IconView::CellType-E<gt>{TEXT}>

The text cell

=item B<IWL::IconView::CellType-E<gt>{IMAGE}>

The image cell

=back

B<ATTRIBUTES> - a hash reference of attributes, with the following possible keys:

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
    my ($self, $type, $attr) = @_;
    return unless %$attr;

    $self->{_options}{cellAttributes}[$type] = $attr;

    return $self;
}

=item B<getCellAttributes> (B<TYPE>)

Sets the get attributes for a particular cell type

Parameter: B<TYPE> - the cell type. See L<IWL::IconView::setCellAttributes|IWL::IconView/setCellAttributes> for more details

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

# Protected
#
sub _realize {
    my $self    = shift;
    my $id      = $self->getId;

    $self->SUPER::_realize;

    my $model = $self->{_model};
    if ($model) {
        if ($model->{options}{limit} && @{$self->{__pageControlEvent}}) {
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

        foreach my $column ($self->{_options}{textColumn}, $self->{_options}{imageColumn}) {
            unless ($column =~ /^[0-9]+$/) {
                my $index = -1;
                foreach (@{$model->{columns}}) {
                    ++$index;
                    if ($_->{name} eq $column) {
                        $column = $index;
                        last;
                    }
                }
            }
        }
    }

    foreach my $attrs (@{$self->{_options}{cellAttributes}}) {
        next unless 'HASH' eq ref $attrs;
        $attrs->{renderTemplate} = $attrs->{renderTemplate}->getContent
            if $attrs->{renderTemplate};
    }
    $self->{_options}{columns} = $default_columns
        unless $self->{_options}{columns} || $self->{_options}{columnWidth};

    my $options = toJSON($self->{_options});

    $self->_appendInitScript("IWL.IconView.create('$id', @{[$model ? $model->toJSON : 'null']}, $options);");
}

sub _init {
    my ($self, %args) = @_;

    $self->{_defaultClass} = 'iconview';
    $args{id} ||= randomize('iconview');

    $self->{__pageControlEvent} = [];

    $self->{_options}{orientation} = defined $args{orientation} ? $args{orientation} : Orientation->{VERTICAL};
    $self->{_options}{columns}     = $args{columns}     if defined $args{columns};
    $self->{_options}{columnWidth} = $args{columnWidth} if defined $args{columnWidth};
    $self->{_options}{textColumn}  = $args{textColumn}  if defined $args{textColumn};
    $self->{_options}{imageColumn} = $args{imageColumn} if defined $args{imageColumn};

    $self->setModel($args{model}) if defined $args{model};

    if ('ARRAY' eq ref $args{cellAttributes}) {
        my $index = 0;
        $self->setCellAttributes($index++, $_)
            foreach @{$args{cellAttributes}};
    }

    delete @args{qw(columns columnWidth orientation textColumn imageColumn cellAttributes model)};

    $self->requiredJs('base.js', 'dist/dragdrop.js', 'dnd.js', 'iconview.js');
    $self->_constructorArguments(%args);

    return $self;
}

IWL::ListModel::addColumnType('IMAGE');

1;

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2008  Viktor Kojouharov. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
