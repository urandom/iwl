#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Tree::Cell;

use strict;

use base 'IWL::Table::Cell';

use IWL::Config qw(%IWLConfig);
use IWL::Image;
use Locale::TextDomain qw(org.bloka.iwl);

use constant IMAGES => {
    row_expand_T   => $IWLConfig{IMAGE_DIR} . '/tree/expander_t.gif',
    row_collapse_T => $IWLConfig{IMAGE_DIR} . '/tree/collapser_t.gif',
    row_T          => $IWLConfig{IMAGE_DIR} . '/tree/t.gif',
    row_L          => $IWLConfig{IMAGE_DIR} . '/tree/l.gif',
    row_expand_L   => $IWLConfig{IMAGE_DIR} . '/tree/expander_l.gif',
    row_collapse_L => $IWLConfig{IMAGE_DIR} . '/tree/collapser_l.gif',
    row_indenter   => $IWLConfig{IMAGE_DIR} . '/tree/indenter.gif',
    row_blank      => $IWLConfig{IMAGE_DIR} . '/tree/blank.gif',
};

=head1 NAME

IWL::Tree::Cell - a cell widget for a tree row

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Table::Cell -> IWL::Tree::Cell

=head1 DESCRIPTION

The Cell widget provides a cell for IWL::Tree. It shouldn't be used standalone. It inherits from IWL:Table::Cell

=head1 CONSTRUCTOR

IWL::Cell->new ()

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);

    # Sortable
    # A callback to be used instead of the default sort js function
    $self->{_sortable} = {enabled => 0, callback => undef, url => undef};

    return $self;
}

=head1 METHODS

=over 4

=item B<makeSortable> ([B<CALLBACK>, B<URL>])

Sorts the tree when the column is clicked. Should only be used for header row cells

Parameters: B<CALLBACK> - an optional callback to be called instead of the default, B<URL> - URL of an ajax script to sort the tree and return the new content (with getContent()), B<CALLBACK> has no effect if B<URL> is set.

=cut

sub makeSortable {
    my ($self, $callback, $url) = @_;

    $self->setStyle(cursor => 'pointer');
    $self->{_sortable} = {enabled => 1, callback => $callback, url => $url};
    return $self;
}

# Protected
#
sub _realize {
    my $self = shift;

    if ($self->{_sortable}{enabled} && $self->{_row} && $self->{_row}{_tree}) {
        my $tree_id = $self->{_row}{_tree}->getId;
	my $callback = $self->{_sortable}{url} ?
	  "\$('$tree_id').ajaxSort(this, '$self->{_sortable}{url}')" :
	  $self->{_sortable}{callback} ?
	  $self->{_sortable}{callback} : "\$('$tree_id').sort(this)";
        $self->signalConnect(click => $callback);
    }
}

# Internal
#
# Prepends the navigation stuff to the cell
sub _blank_indent {
    my $self  = shift;
    my $image = IWL::Image->new;

    $image->set(IMAGES->{row_blank});
    $image->setAlt("Blank image");
    $image->setClass("tree_indent");
    return $image;
}

sub _row_indent {
    my $self  = shift;
    my $image = shift || IWL::Image->new;

    $image->set(IMAGES->{row_indenter});
    $image->setAlt("Indenter");
    $image->setClass("tree_indent");
    return $image;
}

sub _l_junction {
    my $self  = shift;
    my $image = shift || IWL::Image->new;

    $image->set(IMAGES->{row_L});
    $image->setAlt("L-junction");
    $image->setClass("tree_nav");
    return $image;
}

sub _l_collapse {
    my $self  = shift;
    my $image = shift || IWL::Image->new;

    $image->set(IMAGES->{row_collapse_L});
    $image->setAlt("Collapse the row");
    $image->setClass("tree_nav");
    return $image;
}

sub _l_expand {
    my $self  = shift;
    my $image = shift || IWL::Image->new;

    $image->set(IMAGES->{row_expand_L});
    $image->setAlt("Expand the row");
    $image->setClass("tree_nav");
    return $image;
}

sub _t_junction {
    my $self  = shift;
    my $image = shift || IWL::Image->new;

    $image->set(IMAGES->{row_T});
    $image->setAlt("T-junction");
    $image->setClass("tree_nav");
    return $image;
}

sub _t_collapse {
    my $self  = shift;
    my $image = shift || IWL::Image->new;

    $image->set(IMAGES->{row_collapse_T});
    $image->setAlt("Collapse the row");
    $image->setClass("tree_nav");
    return $image;
}

sub _t_expand {
    my $self  = shift;
    my $image = shift || IWL::Image->new;

    $image->set(IMAGES->{row_expand_T});
    $image->setAlt("Expand the row");
    $image->setClass("tree_nav");
    return $image;
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
