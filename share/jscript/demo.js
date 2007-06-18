Event.signalConnect(window, 'domready', demo_init);

function demo_init () {
    displayStatus('To display a widget demo, double click its row');
}

function activate_widgets_response(json) {
    enableView();
    if (!json.data) return;
    var content = $('content');
    $('display_tab').setSelected(true);
    content.removeChildren();
    createHtmlElement(json.data, content);
    content.setStyle({display: 'block'});
}

function contentbox_chooser_change(chooser) {
    $('contentbox').setType(chooser.value);
}

function sortTheMoney(col_index) {
    return function (a, b) {
	var text1 = parseFloat($(a.cells[col_index]).getText().replace(/^\$/, ''));
	var text2 = parseFloat($(b.cells[col_index]).getText().replace(/^\$/, ''));
	if (!text1 || !text2) return;
	return text1 - text2;
    };
}
