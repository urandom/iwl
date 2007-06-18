// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class Button is a class for creating buttons
 * @extends Widget
 * */
var Button = {};
Object.extend(Object.extend(Button, Widget), {
    /**
     * Adjusts the button. Should be called if the button was hidden when created
     * @returns The object
     * */
    adjust: function() {
	var square = 6;
	var corner_size = 6;
	var button = this;
	var image = this.buttonImage;
	var label = this.buttonLabel;
	var topleft = this.buttonParts[0];
	var top = this.buttonParts[1];
	var topright = this.buttonParts[2];
	var left = this.buttonParts[3];
	var content = this.buttonParts[4];
	var right = this.buttonParts[5];
	var bottomleft = this.buttonParts[6];
	var bottom = this.buttonParts[7];
	var bottomright = this.buttonParts[8];
	var state = this.__visibilityToggle();

	if (!content) return;
	if (!label.getText()) {
	    var ml = parseInt(image.getStyle('margin-left')) || 0;
	    var mr = parseInt(image.getStyle('margin-right')) || 0;
	    var ih = parseInt(image.getStyle('height')) || image.height;
	    var text;
	    if (ml != mr)
		image.setStyle({marginLeft: ml + 'px', marginRight: ml + 'px'});
	    label.appendChild(text = 'M'.createTextNode());
	    var height = content.getHeight();
	    label.removeChild(text);
	    if (height)
		content.style.height = height + 'px';
	    image.style.marginTop = (height - ih)/2 + 'px';
	}

	if (this.options.size == 'medium') {
	    square = 3;
	} else if (this.options.size == 'small') {
	    square = 1;
	    corner_size = 4;
	    if (topleft) {
		topleft.style.width = corner_size + "px";
		topleft.style.height = corner_size + "px";
	    }
	    if (topright) {
		topright.style.width = corner_size + "px";
		topright.style.height = corner_size + "px";
	    }
	    if (bottomleft) {
		bottomleft.style.width = corner_size + "px";
		bottomleft.style.height = corner_size + "px";
	    }
	    if (bottomright) {
		bottomright.style.width = corner_size + "px";
		bottomright.style.height = corner_size + "px";
	    }
	    if (image && image.width && image.height) {
		if (image.width > 10)
		    image.width = 10;
		if (image.height > 10)
		    image.height = 10;
	    }
	}

	var dims = content.getDimensions();
	var width = dims.width;
	height = height || dims.height;

	if (state) this.__visibilityToggle(state);
	if (!width || !height) {
	    setTimeout(this.adjust.bind(this), 500);
	    return;
	}

	if (top) {
	    top.style.left = corner_size + 'px';
	    top.style.width = width + 'px';
	    top.style.height = square + 'px';
	}
	if (topright) {
	    topright.style.left = corner_size + width + 'px';
	}
	if (left) {
	    left.style.top = corner_size + 'px';
	    left.style.width = corner_size + 'px';
	    left.style.height = 2 * square + height - (2 * corner_size) + 'px';
	}
	content.style.top = square + 'px';
	content.style.left = corner_size + 'px';
	if (right) {
	    right.style.top = corner_size + 'px';
	    right.style.left = corner_size + width + 'px';
	    right.style.width = corner_size + 'px';
	    right.style.height = 2 * square + height - (2 * corner_size) + 'px';
	}
	if (bottomleft) {
	    bottomleft.style.top = 2 * square + height - corner_size + 'px';
	}
	if (bottom) {
	    bottom.style.left = corner_size + 'px';
	    bottom.style.top = square + height + 'px';
	    bottom.style.width = width + 'px';
	    bottom.style.height = square + 'px';
	}
	if (bottomright) {
	    bottomright.style.left = corner_size + width + 'px';
	    bottomright.style.top = 2 * square + height - corner_size + 'px';
	}
	if (button) {
	    button.style.width = 2 * corner_size + width + 'px';
	    button.style.height = 2 * square + height + 'px';
	}
	this.emitSignal('load');

	return this;
    },
    /**
     * Gets the label of the button
     * @returns The text
     * */
    getLabel: function() {
	if (!this.buttonLabel) return '';
	return this.buttonLabel.getText();
    },
    /**
     * Sets the label of the button
     * @param {String} text The text for the label
     * @returns The object
     * */
    setLabel: function(text) {
        this.buttonLabel.firstChild.nodeValue = text;
        this.adjust();
    },
    /**
     * Submits the form it is in
     * */
    submit: function() {
	if (this.button_submit)
	    this.button_submit.click();
    },
    /**
     * Submits a form
     * @param form_name The name of the form to be submitted
     * */
    submitForm: function(form_name) {
	var form = document[form_name];
	if (form)
	    form.submit();
    },

    _pre_init: function(id, json) {
	var script = $(id + '_noscript');
	if (!script) {
	    setTimeout(function () {this.create(id, json)}.bind(this), 500);
	    return false;
	}
	var container = createHtmlElement(decodeURIComponent(
			json.container).evalJSON(), script.parentNode, script);
	script.parentNode.removeChild(script);
	if (!container) return;
	this.current = $(container);
	return true;
    },
    _init: function(id, json) {
	this.buttonParts = new Array;
	this.buttonImage = null;
	this.buttonLabel = null;
	this.buttonContent = null;
	this.options = Object.extend({
	    size: 'default',
	    submit: false 
	}, arguments[2] || {});
	this.button_submit = this.options.submit ? this.next() : null;
	this.__createElements(json.image, json.label);
	this.__checkComplete();
	Event.observe(this, 'click', this.__clickImageChange.bind(this));
    },

    __clickImageChange: function() {
	removeSelectionFromNode(this.id);
	for (var i = 0; i < this.buttonParts.length; i++)
	    this.__buttonChangeBgImage(this.buttonParts[i], "click");
	setTimeout(function () {this.__defaultImageChange()}.bind(this), 90);
    },
    __defaultImageChange: function(id) {
	for (var i = 0; i < this.buttonParts.length; i++)
	    this.__buttonChangeBgImage(this.buttonParts[i], "default")
    },
    __createElements: function(image, label) {
	var id = this.id;
	var klass = this.className.split(/ /)[0];

	var tl = $(Builder.node('div', {"id": id + '_tl', "class": klass + '_tl'}));
	var t  = $(Builder.node('div', {"id": id + '_top', "class": klass + '_top'}));
	var tr = $(Builder.node('div', {"id": id + '_tr', "class": klass + '_tr'}));
	var l  = $(Builder.node('div', {"id": id + '_l', "class": klass + '_l'}));

	var c  = $(Builder.node('div', {"id": id + '_content', "class": klass + '_content'}));

	var r  = $(Builder.node('div', {"id": id + '_r', "class": klass + '_r'}));
	var bl = $(Builder.node('div', {"id": id + '_bl', "class": klass + '_bl'}));
	var b  = $(Builder.node('div', {"id": id + '_bottom', "class": klass + '_bottom'}));
	var br = $(Builder.node('div', {"id": id + '_br', "class": klass + '_br'}));

	this.appendChild(tl);
	this.appendChild(t);
	this.appendChild(tr);
	this.appendChild(l);
	this.appendChild(c);
	this.appendChild(r);
	this.appendChild(bl);
	this.appendChild(b);
	this.appendChild(br);

	this.buttonParts.push(tl);
	this.buttonParts.push(t);
	this.buttonParts.push(tr);
	this.buttonParts.push(l);
	this.buttonParts.push(c);
	this.buttonParts.push(r);
	this.buttonParts.push(bl);
	this.buttonParts.push(b);
	this.buttonParts.push(br);

	if (image)
	    this.buttonImage = $(createHtmlElement(decodeURIComponent(image).evalJSON(), c));
	this.buttonLabel = $(Builder.node('span', {
	    "id": id + '_label', "class": klass + '_label_' + this.options.size
	}, decodeURIComponent(label)));
	this.buttonContent = c;
	c.appendChild(this.buttonLabel);
    },
    __checkComplete: function() {
	if (!this.buttonImage) {
	    if (!this.buttonLabel.childNodes.length)
		this.buttonLabel.appendChild('&nbsp;'.createTextNode());

	    if (this.buttonLabel.firstChild.nodeValue 
		    && !this.buttonContent.clientWidth)
		setTimeout(this.__checkComplete.bind(this), 100);
	    else
		this.adjust();
	}
    },
    __buttonChangeBgImage: function(part, stat) {
	if (!part) return;
	var url = window.IWLConfig.SKIN_DIR + "/images/button/" + stat + part.id.substr(part.id.lastIndexOf("_"))
	    + ".gif";
	part.style.backgroundImage = "url(" + url + ")";
    },
    __visibilityToggle: function(state) {
	if (!state) {
	    var visible = this.visible();
	    if (ns6 && !visible) {
		var els = this.style;
		var originalVisibility = els.visibility;
		var originalPosition = els.position;
		var originalDisplay = els.display;
		els.visibility = 'hidden';
		els.position = 'absolute';
		els.display = 'block';
		return {visibility: originalVisibility, position: originalPosition, display: originalDisplay};
	    }
	} else {
	    if (ns6) {
		var els = this.style;
		els.display = state.display;
		els.position = state.position;
		els.visibility = state.visibility;
	    }
	}
    }
});
