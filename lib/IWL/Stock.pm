#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Stock;

use strict;

use IWL::Config qw(%IWLConfig);
use Locale::TextDomain qw(org.bloka.iwl);

=head1 NAME

IWL::Stock - stock item support

=head1 DESCRIPTION

The stock object provides an easy reference to stock images and labels for widgets

=head1 CONSTRUCTOR

IWL::Stock->new

=cut

my $Stock = {
    IWL_STOCK_ADD => {
	smallImage => $IWLConfig{ICON_DIR} . "/add." . $IWLConfig{ICON_EXT},
        label       => N__ "Add",
    },
    IWL_STOCK_APPLY => {
	smallImage => $IWLConfig{ICON_DIR} . "/apply." . $IWLConfig{ICON_EXT},
        label       => N__ "Apply",
    },
    IWL_STOCK_BACK => {
        smallImage => $IWLConfig{ICON_DIR} . "/back." . $IWLConfig{ICON_EXT},
        label       => N__ "Back",
    },
    IWL_STOCK_CALENDAR => {
        smallImage => $IWLConfig{ICON_DIR} . "/calendar." . $IWLConfig{ICON_EXT},
        label       => N__ "Calendar",
    },
    IWL_STOCK_CANCEL => {
        smallImage => $IWLConfig{ICON_DIR} . "/cancel." . $IWLConfig{ICON_EXT},
        label       => N__ "Cancel",
    },
    IWL_STOCK_CLEAR => {
        smallImage => $IWLConfig{ICON_DIR} . "/clear." . $IWLConfig{ICON_EXT},
        label       => N__ "Clear",
    },
    IWL_STOCK_CLOSE => {
        smallImage => $IWLConfig{ICON_DIR} . "/close." . $IWLConfig{ICON_EXT},
        label       => N__ "Close",
    },
    IWL_STOCK_DELETE => {
        smallImage => $IWLConfig{ICON_DIR} . "/delete." . $IWLConfig{ICON_EXT},
        label       => N__ "Delete",
    },
    IWL_STOCK_DIRECTORY => {
        smallImage => $IWLConfig{ICON_DIR} . "/directory." . $IWLConfig{ICON_EXT},
        label       => N__ "Directory",
    },
    IWL_STOCK_DOWNLOAD => {
        smallImage => $IWLConfig{ICON_DIR} . "/download." . $IWLConfig{ICON_EXT},
        label       => N__ "Download",
    },
    IWL_STOCK_DIRECTORY_NEW => {
        smallImage => $IWLConfig{ICON_DIR} . "/directory_new." . $IWLConfig{ICON_EXT},
        label       => N__ "Create directory",
    },
    IWL_STOCK_EDIT => {
        smallImage => $IWLConfig{ICON_DIR} . "/edit." . $IWLConfig{ICON_EXT},
        label       => N__ "Edit",
    },
    IWL_STOCK_EXPORT => {
        smallImage => $IWLConfig{ICON_DIR} . "/export." . $IWLConfig{ICON_EXT},
        label       => N__ "Export",
    },
    IWL_STOCK_FULLSCREEN => {
        smallImage => $IWLConfig{ICON_DIR} . "/fullscreen." . $IWLConfig{ICON_EXT},
        label       => N__ "Fullscreen",
    },
    IWL_STOCK_GO => {
        smallImage => $IWLConfig{ICON_DIR} . "/go." . $IWLConfig{ICON_EXT},
        label       => N__ "Go",
    },
    IWL_STOCK_GO_BACK => {
        smallImage => $IWLConfig{ICON_DIR} . "/go_back." . $IWLConfig{ICON_EXT},
        label       => N__ "Go back",
    },
    IWL_STOCK_GO_FORWARD => {
        smallImage => $IWLConfig{ICON_DIR} . "/go_forward." . $IWLConfig{ICON_EXT},
        label       => N__ "Go forward",
    },
    IWL_STOCK_GOTO_FIRST => {
        smallImage => $IWLConfig{ICON_DIR} . "/first." . $IWLConfig{ICON_EXT},
        label       => N__ "Go to first",
    },
    IWL_STOCK_GOTO_LAST => {
        smallImage => $IWLConfig{ICON_DIR} . "/last." . $IWLConfig{ICON_EXT},
        label       => N__ "Go to last",
    },
    IWL_STOCK_HELP => {
        smallImage => $IWLConfig{ICON_DIR} . "/help." . $IWLConfig{ICON_EXT},
        label       => N__ "Help",
    },
    IWL_STOCK_INFO => {
        smallImage => $IWLConfig{ICON_DIR} . "/info." . $IWLConfig{ICON_EXT},
        label       => N__ "Information",
    },
    IWL_STOCK_LOCK => {
        smallImage => $IWLConfig{ICON_DIR} . "/lock." . $IWLConfig{ICON_EXT},
        label       => N__ "Lock",
    },
    IWL_STOCK_NEW => {
        smallImage => $IWLConfig{ICON_DIR} . "/new." . $IWLConfig{ICON_EXT},
        label       => N__ "New",
    },
    IWL_STOCK_NEXT => {
        smallImage => $IWLConfig{ICON_DIR} . "/next." . $IWLConfig{ICON_EXT},
        label       => N__ "Next",
    },
    IWL_STOCK_OK => {
        smallImage => $IWLConfig{ICON_DIR} . "/ok." . $IWLConfig{ICON_EXT},
        label       => N__ "OK",
    },
    IWL_STOCK_PREFERENCES => {
        smallImage => $IWLConfig{ICON_DIR} . "/preferences." . $IWLConfig{ICON_EXT},
        label       => N__ "Preferences",
    },
    IWL_STOCK_PREVIEW => {
        smallImage => $IWLConfig{ICON_DIR} . "/preview." . $IWLConfig{ICON_EXT},
        label       => N__ "Preview",
    },
    IWL_STOCK_REFRESH => {
        smallImage => $IWLConfig{ICON_DIR} . "/refresh." . $IWLConfig{ICON_EXT},
        label       => N__ "Refresh",
    },
    IWL_STOCK_REMOVE => {
        smallImage => $IWLConfig{ICON_DIR} . "/remove." . $IWLConfig{ICON_EXT},
        label       => N__ "Remove",
    },
    IWL_STOCK_SAVE => {
        smallImage => $IWLConfig{ICON_DIR} . "/save." . $IWLConfig{ICON_EXT},
        label       => N__ "Save",
    },
    IWL_STOCK_UPLOAD => {
        smallImage => $IWLConfig{ICON_DIR} . "/upload." . $IWLConfig{ICON_EXT},
        label       => N__ "Upload",
    },

    IWL_STOCK_TEXT_X_GENERIC => {
        smallImage => $IWLConfig{ICON_DIR} . "/text_x_generic." . $IWLConfig{ICON_EXT},
        label       => N__ "Generic Text",
    },
    IWL_STOCK_TEXT_X_ARCHIVE => {
        smallImage => $IWLConfig{ICON_DIR} . "/text_x_archive." . $IWLConfig{ICON_EXT},
        label       => N__ "Generic Text",
    },
};

sub new {
    my $class = shift;
    my $self  = bless {stock => $Stock}, $class;

    return $self;
}

=head1 METHODS

=over 4

=item B<getSmallImage> (B<STOCK_ID>)

Returns the url of the small image of the stock

Parameters: B<STOCK_ID> - the stock id

=cut

sub getSmallImage {
    my ($self, $stock_id) = @_;

    return $Stock->{$stock_id}{smallImage};
}

=item B<getLabel> (B<STOCK_ID>)

Returns the label of the stock

Parameters: B<STOCK_ID> - the stock id

=cut

sub getLabel {
    my ($self, $stock_id) = @_;

    return __ $Stock->{$stock_id}{label};
}

=item B<exists> (B<STOCK_ID>)

Returns true if a stock with the given ID exists

Parameters: B<STOCK_ID> - the stock id

=cut

sub exists {
    my ($self, $stock_id) = @_;

    return exists $Stock->{$stock_id};
}

=item B<add> (B<STOCK_KEY> => B<STOCK_ITEM>, ...)

Adds the given stock items to the list of existing items

Parameters: B<STOCK_KEY> - the stock key of the item, B<STOCK_ITEM> - A stock item to add to the stock repository. It is a hash reference with the following keys:

=over 8

=item B<smallImage>

The URL of the small image, usually with a size of 16x16

=item B<label>

The label for this stock item

=back

=cut

sub add {
    my ($self, %stock_items) = @_;

    $Stock->{$_} = $stock_items{$_} foreach keys %stock_items;
    return $self;
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
