#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::File;

use strict;

use IWL::Widget;

use base 'IWL::Input';

=head1 NAME

IWL::File - a file upload widget

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Input -> IWL::File

=head1 DESCRIPTION

The file widget enables users to select files to pass to the form.

=head1 CONSTRUCTOR

IWL::File->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(%args);

    $self->setAttribute(type => 'file');
    $self->{_defaultClass} = 'file';

    return $self;
}

=head1 METHODS

=over 4

=item B<setAccept> (B<EXPR>)

Sets the accepted mime types. Browsers which support this can use it to filter out the files that a user can choose.

Parameters: B<EXPR> - the expression which is used for filtering

=cut

sub setAccept {
    my ($self, $expr) = @_;

    if ($self->{_file}) {
        return $self->{_file}->setAttribute(accept => $expr);
    } else {
        return $self->setAttribute(accept => $expr);
    }
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
