use Test::More tests => 20;

use IWL::Table;
use IWL::Table::Row;

{
	my $t = IWL::Table->new(cellpadding => 2);
	is($t->setCaption('Foo'), $t);
	is($t->getCaption, 'Foo');
	is($t->setSummary('Summary'), $t);
	is($t->getSummary, 'Summary');

	is($t->setHeaderStyle(height => '50px'), $t);
	is($t->getHeaderStyle('height'), '50px');
	is($t->setBodyStyle(width => '24px'), $t);
	is($t->getBodyStyle('width'), '24px');
	is($t->setFooterStyle(display => 'none'), $t);
	is_deeply({$t->getFooterStyle}, {display => 'none'});
	like($t->getContent, qr(^<table (?:(?:class="(table)"|id="(\1_\d+)"|summary="Summary"|cellspacing="0"|cellpadding="2")\s*){5}><caption (?:(?:class="\1_caption"|id="\2_caption")\s*){2}>Foo</caption>
<tbody (?:(?:class="\1_body"|id="\2_body"|style="width: 24px; ")\s*){3}></tbody>
</table>
$)s); #"
}

{
	my $t = IWL::Table->new;
	is($t->setAlternate(1), $t);
	ok($t->isAlternating);
	is($t->appendHeader(IWL::Table::Row->new->appendTextHeaderCell('Bar')), $t);
	is($t->prependHeader(IWL::Table::Row->new->appendTextHeaderCell('Foo')), $t);
	is($t->appendFooter(IWL::Table::Row->new->appendTextHeaderCell('Beta')), $t);
	is($t->prependFooter(IWL::Table::Row->new->appendTextHeaderCell('Alpha')), $t);
	is($t->appendBody(IWL::Table::Row->new->appendTextCell('More content')), $t);
	is($t->prependBody(IWL::Table::Row->new->appendTextCell('Some content')), $t);
	like($t->getContent, qr(^<table (?:(?:class="(table)"|id="(\1_\d+)"|cellspacing="0"|cellpadding="0")\s*){4}><thead (?:(?:class="\1_header"|id="\2_header")\s*){2}><th class="\1_header_row">Foo</th>
<th class="\1_header_row">Bar</th>
</thead>
<tbody (?:(?:class="\1_body"|id="\2_body")\s*){2}><td class="\1_body_row">Some content</td>
<td class="\1_body_row_alt">More content</td>
</tbody>
<tfoot (?:(?:class="\1_footer"|id="\2_footer")\s*){2}><th class="\1_footer_row">Alpha</th>
<th class="\1_footer_row">Beta</th>
</tfoot>
</table>
)s); #"
}
