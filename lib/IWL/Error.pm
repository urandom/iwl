#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Error;

use strict;

=head1 NAME

IWL::Error - The base error handling class of IWL

=head1 DESCRIPTION

IWL::Error handles registering and reporting errors for IWL

=head1 METHODS

=over 4

# These are more or less copied from the Imperia ErrorSaver module.
=item B<errorList>

In scalar context returns the newline separated contents of the
error stack.  In list context it returns the error stack as a
list.

=cut

sub errorList {
    my $self = shift;

    unless (defined $self->{__errorList}) {
        return wantarray ? () : '';
    }

    if (wantarray) {
        return @{$self->{__errorList}};
    } else {
        join "\n", @{$self->{__errorList}}, '';
    }
}

=item B<errorShift>

Like IWL::Error::errorShift(3pm) but empties the error stack and resets the bad state.

=cut

sub errorShift {
    my $self = shift;

    unless (defined $self->{__errorList}) {
        return wantarray ? () : '';
    }

    $self->_setBad (0);
    if (wantarray) {
        my @errors = @{$self->{__errorList}};
        $self->clearErrors;
        return @errors;
    } else {
        my $errors = join "\n", @{$self->{__errorList}}, '';
        $self->clearErrors;
        return $errors;
    }
}

=item B<chompErrors>

Removes trailing newlines from the messages on the error stack.

=cut

sub chompErrors {
    my $self = shift;
    my $errlist = $self->{__errorList};

    @{$self->{__errorList}} = map { chomp; $_ } @$errlist;
    return $self;
}

=item B<clearErrors>

Empties the error stack.

=cut

sub clearErrors {
    my $self = shift;
    $self->{__errorList} = [];
    return $self;
}

=item B<bad>

Returns the current bad state.

=cut

sub bad {
    shift->{__errorBadState};
}

=item B<errors>

Returns the number of messages on the error stack.

=cut

sub errors {
    my $self = shift;
    return 0 unless $self->{__errorList};

    return scalar @{$self->{__errorList}};
}

=head1 PROTECTED METHODS

The following methods should only be used by classes that inherit
from B<IWL::Error>.

=item B<_pushError> (B<ERROR_LIST>)

Push all strings in C<ERROR_LIST> onto the error stack and returns
false (can be used to return with an error from arbitrary functions).

Parameters: B<ERROR_LIST> - the strings to push into the error stack

=cut

sub _pushError {
    my ($self, @error_list) = @_;

    push @{$self->{__errorList}}, @error_list;

    return;
}

=item B<_pushFatalError> (B<ERROR_LIST>)

Combines IWL::Error::_pushError(3pm) and IWL::Error::_setBad(3pm) to produce a fatal error

Parameters: B<ERROR_LIST> - the strings to push into the error stack

=cut

sub _pushFatalError {
    my ($self, @error_list) = @_;

    return $self->_setBad(1)->_pushError(@error_list);
}

=item B<_setBad> (B<STATE>)

Sets the current bad state.

Parameters: B<STATE> - a boolean state value

=cut

sub _setBad {
    my ($self, $newstate) = @_;
    $self->{__errorBadState} = $newstate;
    return $self;
}

# Aliases
sub errorSuck { IWL::Error::errorShift(@_) }

1;
