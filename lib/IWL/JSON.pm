#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::JSON;

use strict;

use base qw(Exporter);
use vars qw(@EXPORT_OK %EXPORT_TAGS);
@EXPORT_OK = qw(toJSON evalJSON isJSON);
%EXPORT_TAGS = (all => [qw(toJSON evalJSON isJSON)]);

use constant true => 1;
use constant false => '';
use constant null => undef;
use constant undefined => undef;
use constant NaN => undef;
use constant Infinity => undef;

my $number  = qr/^-?\d+(?:\.\d+)?(?:e[-+]\d+)?$/;
my $json    = qr/^[,:{}\[\]0-9.\-+Eaeflnr-u \n\r\t]*$/;
my $escapes = qr/[\x00-\x1f\\"]/;
my %special = ("\b" => '\b', "\t" => '\t', "\n" => '\n', "\f" => '\f', "\r" => '\r', "\\" => '\\\\', '"' => '\"');

=head1 NAME

IWL::JSON - helper functions for converting to and from JSON notation

=head1 DESCRIPTION

IWL::JSON provides function for converting JSON strings to Perl objects and vice versa. It is an exact replica of Prototype JS' toJSON and evalJSON, which means that the equivalent operations in JavaScript should be done with those methods.

=head1 Functions

=over 4

=item B<toJSON> (B<DATA>)

toJSON is a helper function for converting Perl data structures to JSON

Parameters: B<DATA> - The data to convert to JSON

=cut

sub toJSON {
    my $data = shift;
    my $ref  = ref $data;

    return 'null' unless defined $data;

    unless ($ref) {
        return $data if $data =~ $number;
        $data =~ s/($escapes)/
          my $ret = $special{$1} || '\\u00' . unpack('H2', $1);
          $ret;
        /eg;
        return qq{"$data"};
    }
    if ($ref eq 'ARRAY') {
        my @results;
        my @array = @$data;
        foreach my $value (@array) {
            $value = toJSON($value);
            push @results, $value if defined $value;
        }
        return '[' . (join ", ", @results) . ']';
    }
    if ($ref eq 'HASH') {
        my @results;
        my %hash = %$data;
        foreach my $key (keys %hash) {
            my $value = toJSON($hash{$key});
            push @results, (qq{"$key"} . ': ' . $value) if defined $value;
        }
        return '{' . (join ", ", @results) . '}';
    }
    if ($ref eq 'SCALAR' || $ref eq 'REF') {
        my $copy = $$data;
        return toJSON($copy);
    }
    if (UNIVERSAL::isa($data, 'IWL::Object')) {
        return $data->getJSON;
    }
    return;
}

=item B<evalJSON> (B<STRING>, B<SANITIZE>)

evalJSON is a helper function for converting JSON notation to Perl data structures. Internally, in uses Perl's eval(3pm) function.

Parameters: B<STRING> - The JSON string to convert to Perl data, B<SANITIZE> - if sanitize is true, the string is checked for possible malicious code, and eval(3pm) is not called if such is found.

=cut

sub evalJSON {
    my ($string, $sanitize) = @_;
    return if !$string;
    
    if (!$sanitize || isJSON($string)) {
#        $string =~ s/(?<!\\)":/" =>/go;
        $string =~ s/\$/\\\$/go;
        $string =~ s/\@/\\\@/go;
        $string =~ s/\%/\\\%/go;

        my $pos = 0;
        while ($pos = index $string, ':', $pos) {
            last if $pos == -1;
            my $pos2 = $pos++;
            my $sub = substr $string, $pos2 - 2, 2;
            my $quot = substr $sub, 1, 1;
            unless (($quot eq '"' || $quot eq "'") && substr($sub, 0, 1) ne '\\') {
                my @match = substr($string, 0, $pos2) =~ /(?<!\\)"/g;
                next if @match % 2;
            }
            substr $string, $pos2, 1, ' =>';
        }

        my $object = eval('(' . $string . ')');

        return $object;
    }
}

=item B<isJSON> (B<STRING>)

isJSON checks whether the string is in a valid JSON format, and returns true if it is.

=cut

sub isJSON {
    my $string = shift;
    return if !$string;

    $string =~ s/\\./@/go;
    $string =~ s/"[^"\\\n\r]*"//go;
    $string =~ s/\bInfinity\b//go;
    $string =~ s/\bNaN\b//go;
    $string =~ s/\bundefined\b//go;

    return !(!($string =~ $json));
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
