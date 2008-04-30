#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::String;

use Locale::Messages qw(turn_utf_8_off turn_utf_8_on);

use strict;

use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(encodeURI decodeURI encodeURIComponent escape unescape escapeHTML unescapeHTML randomize);

=head1 NAME

IWL::String - string helper functions

=head1 DESCRIPTION

The IWL::String module provides string helper functions

=head1 Functions

=over 4

=item B<encodeURI> (B<STRING>)

Encodes the string by replacing each instance of certain characters by one, two, or three escape sequences representing the UTF-8 encoding of the character. Can be unescaped using the decodeURI javascript function

Parameters: B<STRING> - the string to encode

=cut

sub encodeURI {
    my $string = shift;

    return '' unless defined $string;

    turn_utf_8_off $string;
    $string =~ s/([^0-9a-zA-Z_.!~*'();,\/?:@&=+#\$\x80-\xff-])/'%' . unpack ('H2', $1)/eg;

    return $string
}

=item B<decodeURI> (B<STRING>)

Decodes the string that was previously encoded using encodeString()

Parameters: B<STRING> - the string to decode

=cut

sub decodeURI {
    my $string = shift;

    return '' unless defined $string;

    $string =~ s/\+/ /g;
    $string =~ s/\%([0-9a-fA-F]{2})/pack('H2', $1)/eg;
    turn_utf_8_on $string;

    return $string
}

=item B<encodeURIComponent> (B<STRING>)

Encodes the string by replacing each instance of certain characters by one, two, or three escape sequences representing the UTF-8 encoding of the character. Can be unescaped using the decodeURIComponent javascript function

Parameters: B<STRING> - the string to encode

NOTE: Internet explorer suffers a severe slowdown for decodeURIComponent with large strings. escape(3pm) should be used instead, when not dealing with encoding URI components.

=cut

sub encodeURIComponent {
    my $string = shift;

    return '' unless defined $string;

    turn_utf_8_off $string;
    $string =~ s/([^0-9a-zA-Z_.!~*'()\x80-\xff-])/'%'.unpack('H2', $1)/eg;

    return $string
}

=item B<escape> (B<STRING>, [B<ENCODING>])

Escapes the string with character semantics. Similar to javascript's escape()

Parameters: B<STRING> - the string to escape, B<ENCODING> - optional, the encoding of the string (defaults to 'utf-8')

=cut

sub escape {
    my ($string, $encoding) = @_;
    $encoding ||= 'utf-8';

    return '' unless defined $string;

    $string =~ s/%/%25/g;

    $string =~ s/\\/%5C/g;
    $string =~ s/&/%26/g;
    $string =~ s/</%3C/g;
    $string =~ s/>/%3E/g;
    $string =~ s/\"/%22/g;
    $string =~ s/\'/%27/g;
    $string =~ s/\n/%0A/g;

    return $string;
}

=item B<unescape> (B<STRING>)

Unescapes a string, previously escaped using escape(3pm)

Parameters: B<STRING> - the string to unescape

=cut

sub unescape {
    my ($string) = @_;
    $string =~ s/%u([0-9a-f]{4})/\\x{$1}/ig;
    $string =~ s/%([0-9a-f]{2})/\\x{$1}/ig;

    $string = eval qq|"$string"|;

    return $string;
}

=item B<escapeHTML> (B<STRING>)

Converts HTML special characters to entity elements

Parameters: B<STRING> - the string to escape 

=cut

sub escapeHTML {
    my $string = shift;

    return '' unless defined $string;
    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/\"/&quot;/g; #"
    $string =~ s/\'/&\#39;/g; #'

    return $string;
}

=item B<unescapeHTML> (B<STRING>)

Converts entity elements to HTML special characters

Parameters: B<STRING> - the string to unescape 

=cut

sub unescapeHTML {
    my $string = shift;

    return '' unless defined $string;
    $string =~ s/&amp;/&/g;
    $string =~ s/&lt;/</g;
    $string =~ s/&gt;/>/g;
    $string =~ s/&quot;/\"/g;
    $string =~ s/&\#39;/\'/g;

    return $string;
}

=item B<randomize> (B<STRING>)

Randomizes the string by appending an underscore and a random floating point number to it

Parameters: B<STRING> - the string to randomize

=cut

sub randomize {
    my $string = shift;

    return '' unless defined $string;
    $string .= '_' . int(rand(1e10));
    $string =~ s/\.//g;

    return $string;
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
