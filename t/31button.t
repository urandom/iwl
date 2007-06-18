use Test::More tests => 2;

use IWL::Button;

{
	my $button = IWL::Button->newFromStock('IWL_STOCK_SAVE', id => 'foo');
	is($button->getContent, <<EOF);
<script src="/jscript/dist/prototype.js" type="text/javascript"></script>
<script src="/jscript/prototype_extensions.js" type="text/javascript"></script>
<script src="/jscript/dist/builder.js" type="text/javascript"></script>
<script src="/jscript/dist/effects.js" type="text/javascript"></script>
<script src="/jscript/dist/controls.js" type="text/javascript"></script>
<script src="/jscript/scriptaculous_extensions.js" type="text/javascript"></script>
<script src="/jscript/base.js" type="text/javascript"></script>
<script src="/jscript/button.js" type="text/javascript"></script>
<noscript class="button_noscript" id="foo_noscript"></noscript>
<script type="text/javascript">Button.create('foo', {container:"%7b%22tag%22%3a%22div%22%2c%22attributes%22%3a%7b%22class%22%3a%22button%22%2c%22id%22%3a%22foo%22%7d%7d",image:"%7b%22tag%22%3a%22img%22%2c%22attributes%22%3a%7b%22alt%22%3a%22Save%22%2c%22src%22%3a%22%2fmy%2fskin%2fdarkness%2ftiny%2fsave.gif%22%2c%22onload%22%3a%22%24('foo').adjust()%22%2c%22class%22%3a%22button_image%22%2c%22title%22%3a%22Save%22%2c%22id%22%3a%22foo_image%22%7d%7d",label:"Save"}, {"submit":0,"size":"default"});</script>
EOF
	is_deeply($button->getObject, {
			after_objects => [{
					tag => 'script',
					children => [{
							text => 'Button.create(\'foo\', {container:"%7b%22tag%22%3a%22div%22%2c%22attributes%22%3a%7b%22class%22%3a%22button%22%2c%22id%22%3a%22foo%22%7d%7d",image:"%7b%22tag%22%3a%22img%22%2c%22attributes%22%3a%7b%22alt%22%3a%22Save%22%2c%22src%22%3a%22%2fmy%2fskin%2fdarkness%2ftiny%2fsave.gif%22%2c%22onload%22%3a%22%24(\'foo\').adjust()%22%2c%22class%22%3a%22button_image%22%2c%22title%22%3a%22Save%22%2c%22id%22%3a%22foo_image%22%7d%7d",label:"Save"}, {"submit":0,"size":"default"});'
					}],
					attributes => {
						type => 'text/javascript'
					}
			}],
			tag => 'noscript',
			attributes => {
				id => 'foo_noscript',
				class => 'button_noscript'
			}
	});
}
