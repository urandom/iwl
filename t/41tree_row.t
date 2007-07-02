use Test::More tests => 27;

use IWL::Tree::Row;

{
	my $row = IWL::Tree::Row->new;
	my $child1 = IWL::Tree::Row->new, my $child2 = IWL::Tree::Row->new, my $child3 = IWL::Tree::Row->new;
	isa_ok($child1->prependTextHeaderCell('Bar'), 'IWL::Tree::Cell');
	isa_ok($child2->prependCell(IWL::Text->new('Foo')), 'IWL::Tree::Cell');
	is($row->prependRow($child1), $row);
	is($row->appendRow($child2), $row);
	is($child1->appendRow($child3), $child1);
	is_deeply($row->getChildRows, [$child1, $child3, $child2]);
	is_deeply($row->getChildRows(1), [$child1, $child2]);
	is($row->expand(1), $row);
	is($row->makeParent, $row);
	is_deeply($child3->getPath, [0, 0, 0]);
	is($row->setPath([1, 5]), $row);
	is_deeply($row->getPath, [1, 5]);
	is($row->setPath(2, 5), $row);
	is_deeply($child3->getPath, [2, 5, 0, 0]);
	is($child2->getPrevRow, $child1);
	is($child1->getNextRow, $child2);
	ok(!$row->isSelected);
	is($row->setSelected(1), $row);
	ok($row->isSelected);
	is($child3->getParentRow, $child1);
	is($row->getFirstChildRow, $child1);
	is($row->getLastChildRow, $child2);
	is($row->getFromPath(2, 5, 0, 0), undef); # Not part of a tree
	is($row->setNavigation, $row);
	is($row->makeSortable(5), undef);
	is($child1->makeSortable(0), $child1);
	like($row->getContent, qr(^<tr (?:(?:iwl:treeRowData=".*?"|class="(tree_row)"|id="\1_\d+")\s*){3}></tr>
<tr (?:(?:iwl:treeRowData=".*?"|class="\1"|id="\1_\d+")\s*){3}><th style="cursor: pointer; "><span (?:(?:class="tree_nav_con"|id="\1_\d+_nav_con")\s*){2}></span>
Bar</th>
</tr>
<tr (?:(?:iwl:treeRowData=".*?"|class="\1"|id="\1_\d+"|style="display: none; ")\s*){4}></tr>
<tr (?:(?:iwl:treeRowData=".*?"|class="\1"|id="\1_\d+")\s*){3}><td><span (?:(?:class="tree_nav_con"|id="\1_\d+_nav_con")\s*){2}></span>
Foo</td>
</tr>
$)s);	#"
}
