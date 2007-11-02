// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.Button is a class for creating buttons
 * @extends IWL.Widget
 * */
IWL.Button = Object.extend(Object.extend({}, IWL.Widget), (function () {
    function disabledImageChange() {
        for (var i = 0; i < this.buttonParts.length; i++)
            changeBackground.call(this, this.buttonParts[i], "disabled");
    }

    function clickImageChange() {
        IWL.removeSelection();
        for (var i = 0; i < this.buttonParts.length; i++)
            changeBackground.call(this, this.buttonParts[i], "click");
    }

    function defaultImageChange(id) {
        for (var i = 0; i < this.buttonParts.length; i++)
            changeBackground.call(this, this.buttonParts[i], "default")
    }

    function createElements(image, label) {
        var id = this.id;
        var className = $A(this.classNames()).first();

        this.update(
            '<div id="' + id + '_tl" class="'      + className + '_tl"></div>'      + 
            '<div id="' + id + '_top" class="'     + className + '_top"></div>'     + 
            '<div id="' + id + '_tr" class="'      + className + '_tr"></div>'      + 
            '<div id="' + id + '_l" class="'       + className + '_l"></div>'       + 
            '<div id="' + id + '_content" class="' + className + '_content"></div>' + 
            '<div id="' + id + '_r" class="'       + className + '_r"></div>'       + 
            '<div id="' + id + '_bl" class="'      + className + '_bl"></div>'      + 
            '<div id="' + id + '_bottom" class="'  + className + '_bottom"></div>'  + 
            '<div id="' + id + '_br" class="'      + className + '_br"></div>'
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
    }

    function checkComplete() {
        if (!this.buttonImage) {
            if (this.buttonLabel.getText()
                    && !this.buttonContent.clientWidth)
                checkComplete.bind(this).delay(0.1);
            else
                this.adjust();
        }
    }

    function changeBackground(part, stat) {
        if (!part) return;
        var url = IWL.Config.IMAGE_DIR + "/button/" + stat + part.id.substr(part.id.lastIndexOf("_"))
            + ".gif";
        part.style.backgroundImage = "url(" + url + ")";
    }

    function visibilityToggle(state) {
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
                return false;
            }
        }
    }

    function createDisabledLayer() {
        if (!this.parentNode)
            return;

        this.disabledLayer = new Element('div', {
                className: $A(this.classNames()).first() + '_disabled_layer'
            });
        if (this.nextSibling)
            this.parentNode.insertBefore(this.disabledLayer, this.nextSibling);
        else
            this.parentNode.appendChild(this.disabledLayer);
        this.disabledLayer.signalConnect('click', function(event) {event.stop()});

        return this;
    }

    function positionDisabledLayer() {
        if (!this.disabledLayer) return;

        var floatStyle   = this.getStyle('float');
        var dims         = this.getDimensions();
        var marginTop    = parseFloat(this.getStyle('margin-top'))    || 0;
        var marginRight  = parseFloat(this.getStyle('margin-right'))  || 0;
        var marginBottom = parseFloat(this.getStyle('margin-bottom')) || 0;
        var marginLeft   = parseFloat(this.getStyle('margin-left'))   || 0;
        var zIndex       = parseInt(this.getStyle('z-index'));

        if (!floatStyle || floatStyle == 'none')
            this.disabledLayer.style.margin = '-' + (dims.height + marginBottom) + 'px ' + marginRight + 'px ' + marginBottom + 'px ' + marginRight + 'px';
        else if (floatStyle == 'left')
            this.disabledLayer.style.margin = marginTop + 'px ' + marginRight + 'px ' + marginBottom + 'px ' + '-' + (dims.width + marginRight) + 'px';
        else
            this.disabledLayer.style.margin = marginTop + 'px ' + '-' + (dims.width + marginLeft) + 'px ' + marginBottom + 'px ' + marginLeft + 'px';

        this.disabledLayer.setStyle({
                width: dims.width + 'px',
                height: dims.height + 'px',
                zIndex: zIndex + 1, position: 'relative',
                'float': floatStyle, background: 'white',
                opacity: 0.01
            });
    }

    function removeDisabledLayer() {
        if (!this.disabledLayer)
            return;

        this.disabledLayer.remove();
        this.disabledLayer = undefined;
        return this;
    }

    function disableButton(event) {
        positionDisabledLayer.call(this);
    }

    function submitForm() {
        if (!this.form) return;
        if (this.hidden)
            this.form.appendChild(this.hidden);
        this.form.submit();
        if (this.hidden)
            this.hidden.remove();
    }

    function init(json) {
        createElements.call(this, json.image, json.label);
        checkComplete.call(this);
        this.observe('mousedown', clickImageChange.bindAsEventListener(this));
        this.observe('mouseup', defaultImageChange.bindAsEventListener(this));
        if (this.options.disabled)
            this.setDisabled(true);
        if (this.options.submit)
            this.setSubmit.apply(this, Object.isArray(this.options.submit) ? this.options.submit : []);
    }

    return {
        /**
         * Adjusts the button. Should be called if the button was hidden when created
         * @returns The object
         * */
        adjust: function() {
            var square = 6;
            var corner_size = 6;
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
            var state = visibilityToggle.call(this);

            if (!content) return;
            if (!label.getText()) {
                var text;
                if (image) {
                    var ml = parseFloat(image.getStyle('margin-left')) || 0;
                    var mr = parseFloat(image.getStyle('margin-right')) || 0;
                    var ih = parseFloat(image.getStyle('height')) || image.height;
                    if (ml != mr)
                        image.setStyle({marginLeft: ml + 'px', marginRight: ml + 'px'});
                }
                label.appendChild(text = 'M'.createTextNode());
                var height = content.getHeight();
                label.removeChild(text);
                if (height)
                    content.style.height = height + 'px';
                if (image)
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

            if (state) visibilityToggle.call(this, state);
            if (!width || !height) {
                this.adjust.bind(this).delay(0.5);
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
            this.style.width = 2 * corner_size + width + 'px';
            this.style.height = 2 * square + height + 'px';

            if (!this.loaded) {
                this.loaded = true;
                this.emitSignal('iwl:load');
            }

            return this.emitSignal('iwl:adjust');
        },
        /**
         * Gets the label of the button
         * @returns The text
         * */
        getLabel: function() {
            return this.buttonLabel.getText();
        },
        /**
         * Sets the label of the button
         * @param {String} text The text for the label
         * @returns The object
         * */
        setLabel: function(text) {
            this.buttonLabel.update(text && text.toString ? text.toString() : '');
            return this.adjust();
        },
        /**
         * Gets the image of the button
         * @returns The text
         * */
        getImage: function() {
            return this.buttonImage;
        },
        /**
         * Sets the image of the button
         * @param {String} source The source location for the image
         * @returns The object
         * */
        setImage: function(source) {
            if (source) {
                if (!this.buttonImage)
                    this.buttonImage = this.buttonContent.insertBefore(
                        new Element('img', {
                                src: source,
                                id: this.id + '_image',
                                className: 'image ' + $A(this.classNames()).first() + '_image'
                            }),
                        this.buttonLabel
                    );
                else
                    this.buttonImage.src = source;
                this.buttonImage.observe('load', this.adjust.bind(this));
            } else {
                this.buttonImage.remove();
                this.buttonImage = undefined;
            }
            this.adjust();
            return this;
        },
        /**
         * Sets the button as a form submit button
         * @param {String} name The name of the parameter to submit along with the form
         * @param {String} value The value of the parameter
         * @param formName the form which to submit
         * */
        setSubmit: function(name, value, formName) {
            if (this.submit) return;
            if (Object.isElement(formName))
                this.form = formName;
            else
                this.form = document[formName] || this.up('form');
            if (!this.form) return;
            if (Object.isString(name) && name)
                this.hidden = new Element('input', {type: 'hidden', name: name, value: value});
            this.signalConnect('click', submitForm.bind(this));
            this.submit = true;
            return this;
        },
        /**
         * Sets whether the button should be disabled
         * @param {Boolean} disabled True if the button is disabled
         * */
        setDisabled: function(disabled) {
            if (disabled == this._disabled)
                return;
            if (!document.loaded) {
                document.observe('dom:loaded', this.setDisabled.bind(this, disabled));
                return this;
            }
            if (!this.loaded)
                return this.signalConnect('iwl:load', this.setDisabled.bind(this, disabled));

            if (disabled) {
                this.addClassName($A(this.classNames()).first() + '_disabled');
                this._disabled = true;
                disabledImageChange.call(this);
                createDisabledLayer.call(this);
                positionDisabledLayer.call(this);
                this.signalConnect('iwl:adjust', disableButton);
                this.adjust();
            } else {
                this.removeClassName($A(this.classNames()).first() + '_disabled');
                this._disabled = false;
                defaultImageChange.call(this);
                removeDisabledLayer.call(this);
                this.signalDisconnect('iwl:adjust', disableButton);
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
                this.create.bind(this, id, json, arguments[2]).delay(0.5);
                return false;
            }
            var container = script.up().createHtmlElement(json.container, script);
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
            this.loaded = false;
            if (document.loaded)
                init.call(this, json);
            else
                document.observe('dom:loaded', init.bind(this, json));
        }
    }
})());

/* Deprecated */
var Button = IWL.Button;
