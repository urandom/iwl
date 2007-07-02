use Test::More tests => 10;

use IWL::Table::Row;

{
	my $row = IWL::Table::Row->new;
	isa_ok($row->appendHeaderCell(IWL::Text->new('Foo')), 'IWL::Table::Cell');
	isa_ok($row->appendTextHeaderCell('Bar'), 'IWL::Table::Cell');

	isa_ok($row->prependHeaderCell(IWL::Text->new('Alpha')), 'IWL::Table::Cell');
	isa_ok($row->prependTextHeaderCell('Beta'), 'IWL::Table::Cell');
	like($row->getContent, qr(^<tr (?:(?:class="(table_row)"|id="\1_\d+")\s*){2}><th>Beta</th>
<th>Alpha</th>
<th>Foo</th>
<th>Bar</th>
</tr>
$)s); #"
}

{
	my $row = IWL::Table::Row->new;
	isa_ok($row->appendCell(IWL::Text->new('Foo')), 'IWL::Table::Cell');
	isa_ok($row->appendTextCell('Bar'), 'IWL::Table::Cell');

	isa_ok($row->prependCell(IWL::Text->new('Alpha')), 'IWL::Table::Cell');
	isa_ok($row->prependTextCell('Beta'), 'IWL::Table::Cell');
	like($row->getContent, qr(^<tr (?:(?:class="(table_row)"|id="\1_\d+")\s*){2}><td>Beta</td>
<td>Alpha</td>
<td>Foo</td>
<td>Bar</td>
</tr>
$)s); #"
}
