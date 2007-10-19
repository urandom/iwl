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
        this.__loaded = false;
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
	this.emitSignal('iwl:load');
        this.__loaded = true;

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
    /**
     * Sets whether the button should be disabled
     * @param {Boolean} disabled True if the button is disabled
     * */
    setDisabled: function(disabled) {
        if (disabled == this._disabled)
            return;
        if (!this.__loaded)
            this.signalConnect('load', this.setDisabled.bind(this, disabled));
        if (disabled) {
            this.addClassName($A(this.classNames()).first() + '_disabled');
            this._disabled = true;
            this.__disabledImageChange();
            setTimeout(function() {
                this.__createDisabledLayer();
            }.bind(this), 500);
            this.adjust();
        } else {
            this.removeClassName($A(this.classNames()).first() + '_disabled');
            this._disabled = false;
            this.__defaultImageChange();
            this.__deleteDisabledLayer();
            this.adjust();
        }
        return this;
    },
    /**
     * Checks whether the button is disabled
     * @returns True if the button is disabled
     * @type Boolean
     * Note: isDisabled is a read-only attribute in Internet Explorer
     * */
    isNotEnabled: function() {
        return this._disabled;
    },

    _preInit: function(id, json) {
        var script = $(id + '_noscript');
        if (!script) {
            setTimeout(function () {this.create(id, json)}.bind(this), 500);
            return false;
        }
        var container = createHtmlElement(json.container, script.parentNode, script);
        script.remove();
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
            disabled: false,
	    submit: false 
	}, arguments[2] || {});
	this.button_submit = this.options.submit ? this.next() : null;
        this.__loaded = false;
	this.__createElements(json.image, json.label);
	this.__checkComplete();
	this.observe('mousedown', this.__clickImageChange.bindAsEventListener(this));
	this.observe('mouseup', this.__defaultImageChange.bindAsEventListener(this));
        if (this.options.disabled)
            this.setDisabled(true);
    },

    __disabledImageChange: function() {
	for (var i = 0; i < this.buttonParts.length; i++)
	    this.__buttonChangeBgImage(this.buttonParts[i], "disabled");
    },
    __clickImageChange: function() {
	removeSelection();
	for (var i = 0; i < this.buttonParts.length; i++)
	    this.__buttonChangeBgImage(this.buttonParts[i], "click");
    },
    __defaultImageChange: function(id) {
	for (var i = 0; i < this.buttonParts.length; i++)
	    this.__buttonChangeBgImage(this.buttonParts[i], "default")
    },
    __createElements: function(image, label) {
	var id = this.id;
	var className = $A(this.classNames()).first();

	this.update(
	    '<div id="' + id + '_tl" class="' + className + '_tl"></div>' +
	    '<div id="' + id + '_top" class="' + className + '_top"></div>' +
	    '<div id="' + id + '_tr" class="' + className + '_tr"></div>' +
	    '<div id="' + id + '_l" class="' + className + '_l"></div>' +
	    '<div id="' + id + '_content" class="' + className + '_content"></div>' +
	    '<div id="' + id + '_r" class="' + className + '_r"></div>' +
	    '<div id="' + id + '_bl" class="' + className + '_bl"></div>' +
	    '<div id="' + id + '_bottom" class="' + className + '_bottom"></div>' +
	    '<div id="' + id + '_br" class="' + className + '_br"></div>'
	);

	this.buttonParts = this.childElements();
	this.buttonContent = $(id + '_content');

	image = image ? unescape(image) : '';
        var classNames = className + '_label ' + className + '_label_' + this.options.size;
	this.buttonContent.update(
	    image + '<span id="' + id + '_label" class="' + classNames + '">' +
		unescape(label) + '</span>'
	);
	this.buttonImage = $(id + '_image');
	this.buttonLabel = $(id + '_label');
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
	var url = window.IWLConfig.IMAGE_DIR + "/button/" + stat + part.id.substr(part.id.lastIndexOf("_"))
	    + ".gif";
	part.style.backgroundImage = "url(" + url + ")";
    },
    __visibilityToggle: function(state) {
	if (!state) {
	    var visible = this.visible();
	    if (Prototype.Browser.Gecko && !visible) {
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
	    if (Prototype.Browser.Gecko) {
		var els = this.style;
		els.display = state.display;
		els.position = state.position;
		els.visibility = state.visibility;
	    }
	}
    },
    __createDisabledLayer: function() {
        if (!this.parentNode)
            return;

        var position     = this.cumulativeOffset();
        var dims         = this.getDimensions();
        var marginTop    = parseInt(this.getStyle('margin-top'));
        var marginRight  = parseInt(this.getStyle('margin-right'));
        var marginBottom = parseInt(this.getStyle('margin-bottom'));
        var marginLeft   = parseInt(this.getStyle('margin-left'));
        var zIndex       = parseInt(this.getStyle('z-index'));
        if (isNaN(marginTop))    marginTop    = 0;
        if (isNaN(marginRight))  marginRight  = 0;
        if (isNaN(marginBottom)) marginBottom = 0;
        if (isNaN(marginLeft))   marginLeft   = 0;
        if (isNaN(zIndex))       zIndex       = 0;

        this.disabledLayer = new Element('div', {
                className: $A(this.classNames()).first() + '_disabled_layer'
            });
        this.disabledLayer.setStyle({
                opacity: 0.01, position: 'absolute',
                width: dims.width + marginRight + marginLeft + 'px',
                height: dims.height + marginTop + marginBottom + 'px',
                zIndex: zIndex + 1, backgroundColor: 'white',
                left: position[0] - marginLeft + 'px',
                top: position[1] - marginTop + 'px'
            });
        this.disabledLayer.signalConnect('click', function(evt) {
                evt.stop();
            });
        this.parentNode.appendChild(this.disabledLayer);

        return this;
    },
    __deleteDisabledLayer: function() {
        if (!this.disabledLayer)
            return;

        this.disabledLayer.remove();
        this.disabledLayer = undefined;
        return this;
    }
});
