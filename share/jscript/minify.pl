use JavaScript::Minifier qw(minify);
open(INFILE, 'tree.js') or die;
open(OUTFILE, '> myScript-min.js') or die;
minify(input => *INFILE, outfile => *OUTFILE);
close(INFILE);
close(OUTFILE);

