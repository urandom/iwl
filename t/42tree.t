use Test::More tests => 12;

use IWL::Tree;
use IWL::Tree::Row;

my $t = IWL::Tree->new(list => 1);
ok($t->isList);
is($t->setList(0), $t);
ok(!$t->isList);
is_deeply([$t->getAllBodyRows], []);
is($t->setSortableCallback(2, 'alert'), $t);
my $row1 = IWL::Tree::Row->new;
my $row2 = IWL::Tree::Row->new;
$row1->appendTextCell('Bar');
$row2->appendTextCell('Foo');
is($t->appendRow($row1), $t);
is($t->prependRow($row2), $t);
is($t->appendHeader(IWL::Tree::Row->new(id => 'header2')), $t);
is($t->prependHeader(IWL::Tree::Row->new(id => 'header1')), $t);
is($t->appendFooter(IWL::Tree::Row->new(id => 'footer2')), $t);
is($t->prependFooter(IWL::Tree::Row->new(id => 'footer1')), $t);
like($t->getContent, qr(.*dist/prototype.js.*prototype_extensions.js.*dist/effects.js.*dist/controls.js.*scriptaculous_extensions.js.*base.js.*tree.js.*?
<table (?:(?:class="(tree)"|id="(\1_\d+)"|cellspacing="0"|cellpadding="0")\s*){4}><thead (?:(?:class="\1_header"|id="\2_header")\s*){2}><tr (?:(?:iwl:treeRowData=".*?"|id="header1"|class="\1_row \1_header_row")\s*){3}></tr>
<tr (?:(?:iwl:treeRowData=".*?"|id="header2"|class="\1_row \1_header_row")\s*){3}></tr>
</thead>
<tbody (?:(?:class="\1_body"|id="\2_body")\s*){2}><tr (?:(?:iwl:treeRowData=".*?"|id="\1_row_\d+"|class="\1_row")\s*){3}><td><span (?:(?:class="\1_nav_con"|id="\1_row_\d+_nav_con")\s*){2}></span>
Foo</td>
</tr>
<tr (?:(?:iwl:treeRowData=".*?"|id="\1_row_\d+"|class="\1_row")\s*){3}><td><span (?:(?:class="\1_nav_con"|id="\1_row_\d+_nav_con")\s*){2}></span>
Bar</td>
</tr>
</tbody>
<tfoot (?:(?:class="\1_footer"|id="\2_footer")\s*){2}><tr (?:(?:iwl:treeRowData=".*?"|id="footer1"|class="\1_row \1_footer_row")\s*){3}></tr>
<tr (?:(?:iwl:treeRowData=".*?"|id="footer2"|class="\1_row \1_footer_row")\s*){3}></tr>
</tfoot>
</table>
<script.*?Tree.create.'\2', {.*?</script>
$)s);
