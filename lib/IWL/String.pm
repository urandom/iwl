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
    my $copy = $string;

    turn_utf_8_off $copy;
    $copy =~ s/([^0-9a-zA-Z_.!~*'();,\/?:@&=+#\$\x80-\xff-])/'%' . unpack ('H2', $1)/eg;

    return $copy
}

=item B<decodeURI> (B<STRING>)

Decodes the string that was previously encoded using encodeString()

Parameters: B<STRING> - the string to decode

=cut

sub decodeURI {
    my $string = shift;

    return '' unless defined $string;
    my $copy = $string;

    $copy =~ s/\+/ /g;
    $copy =~ s/\%([0-9a-fA-F]{2})/pack('H2', $1)/eg;
    turn_utf_8_on $copy;

    return $copy
}

=item B<encodeURIComponent> (B<STRING>)

Encodes the string by replacing each instance of certain characters by one, two, or three escape sequences representing the UTF-8 encoding of the character. Can be unescaped using the decodeURIComponent javascript function

Parameters: B<STRING> - the string to encode

NOTE: Internet explorer suffers a severe slowdown for decodeURIComponent with large strings. escape(3pm) should be used instead.

=cut

sub encodeURIComponent {
    my $string = shift;

    return '' unless defined $string;
    my $copy = $string;

    turn_utf_8_off $copy;
    $copy =~ s/([^0-9a-zA-Z_.!~*'()\x80-\xff-])/'%'.unpack('H2', $1)/eg;

    return $copy
}

=item B<escape> (B<STRING>, [B<ENCODING>])

Escapes the string with character semantics. Similar to javascript's escape()

Parameters: B<STRING> - the string to escape, B<ENCODING> - optional, the encoding of the string (defaults to 'utf-8')

=cut

sub escape {
    my ($string, $encoding) = @_;
    $encoding ||= 'utf-8';

    return '' unless defined $string;

    require Locale::Recode;

    my $cd = Locale::Recode->new(
	from => $encoding,
	to => 'INTERNAL');

    $cd->recode($string);

    my $result = '';
    foreach my $ord (@$string) {
	if ($ord > 0xff) {
	    $result .= sprintf "%%u%04X", $ord;
	} elsif (
	         ($ord >= 0x2a && $ord < 0x2c)
	      || ($ord >= 0x2d && $ord < 0x39)
	      || ($ord >= 0x40 && $ord < 0x5b)
	      || ($ord >= 0x61 && $ord < 0x7b)
	      ||  $ord == 0x5f) {
	    $result .= chr $ord;
	} else {
	    $result .= sprintf "%%%02X", $ord;
	}
    }

    return $result;

}

=item B<unescape> (B<STRING>)

Unescapes a string, previously escaped using escape(3pm)

Parameters: B<STRING> - the string to unescape

=cut

sub unescape {
    my ($string) = @_;
    $string =~ s/%u([0-9a-f]{4})/chr(hex($1))/eig;
    $string =~ s/%([0-9a-f]{2})/chr(hex($1))/eig;

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
    $string .= '_' . rand(65536);
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
