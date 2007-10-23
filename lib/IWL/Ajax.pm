#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Ajax;

use strict;

use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(updaterCallback);

use IWL::JSON qw(toJSON);

=head1 NAME

IWL::Ajax - helper functions for prototypejs's Ajax object

=head1 Functions

=over 4

=item B<updaterCallback> (B<ID>, B<URL>, [B<%OPTIONS>])

updaterCallback is a helper wrapper around Ajax.Updater, to be used as a callback to a signal. Upon the signal activation, it will use Ajax.Updater to call a script, which must return valid html syntax that will be used to replace, or update the contents of a container

Parameters: B<ID> - the id of the container which will be updated, B<URL> - the url of the script that will provide the content, B<%OPTIONS> - a hash with the following options:

=over 8

=item I<parameters> 

A hash or a javascript hash options of the parameters to be passed to the script

=item I<evalScripts> 

True, if any script elements in the response should be evaluated using javascript's eval() function

=item I<insertion>

If omitted, the contents of the container will be replaced with the response of the script. Otherwise, depeding on the value, the reponse will be placed around the exsting content. Valid values are: I<after> - will be inserted as the next sibling of the container, I<before> - will be inserted as the previous sibling of the container, I<bottom> - will be inserted as the last child of the container, I<top> - will be inserted as the first child of the container

=item I<onComplete> 

A javascript function to be called after the update takes place

=back

=back

=cut

sub updaterCallback {
    my ($id, $url, %options) = @_;
    return unless $id && $url;
    my $options = 'onException: IWL.exceptionHandler';

    $options .= ",onComplete: " . $options{onComplete} if $options{onComplete};
    if ($options{parameters}) {
	if (ref $options{parameters} eq 'HASH') {
	    $options .= ",parameters:" . toJSON($options{parameters});
	} elsif (!ref $options{parameters}) {
	    $options .= ",parameters:{" . $options{parameters} . "}";
	}
    }

    $options .= ",evalScripts: true" if $options{evalScripts};
    $options .= {
	after  => ",insertion: 'after'",
	before => ",insertion: 'before'",
	bottom => ",insertion: 'bottom'",
	top    => ",insertion: 'top'",
    }->{$options{insertion}} if $options{insertion};

    return "new Ajax.Updater('$id', '$url', {$options})";
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
