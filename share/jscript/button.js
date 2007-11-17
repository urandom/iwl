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

    function createElements() {
        var id = this.id;
        var className = $A(this.classNames()).first();

        this.buttonParts = this.childElements();
        this.buttonContent = $(id + '_content');

        var classNames = className + '_label ' + className + '_label_' + this.options.size;
        this.buttonContent.insert(
            '<span id="' + id + '_label" class="' + classNames + '">' +
                unescape(this.options.label) + '</span>'
        );
        this.buttonImage = $(id + '_image');
        this.buttonLabel = $(id + '_label');
    }

    function checkComplete() {
        if (!this.buttonImage || this.buttonImage.complete) {
            if (this.buttonLabel.getText()
                    && !this.buttonContent.clientWidth)
                checkComplete.bind(this).delay(0.1);
            else
                adjust.call(this);
        } else {
            this.buttonImage.signalConnect('load', checkComplete.bind(this));
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

    function adjust() {
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
                if (this.options.size == 'small' && ih > 10) ih = 10;
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
                var aspect = image.width / image.height;
                if (image.height > 10) {
                    image.style.width = 10 * aspect + 'px';
                    image.style.height = '10px';
                }
            }
        }

        var dims = content.getDimensions();
        var width = dims.width;
        height = height || dims.height;

        if (state) visibilityToggle.call(this, state);
        if (!width || !height) {
            adjust.bind(this).delay(0.5);
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
            this.style.visibility = this.options.visibility || '';
            this.loaded = true;
            this.emitSignal('iwl:load');
        }

        return this.emitSignal('iwl:adjust');
    }

    return {
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
            return adjust.call(this);
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
                this.buttonImage.observe('load', adjust.bind(this));
            } else {
                this.buttonImage.remove();
                this.buttonImage = undefined;
            }
            return adjust.call(this);
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
            if (!this.loaded)
                return this.signalConnect('iwl:load', this.setDisabled.bind(this, disabled));

            if (disabled) {
                this.addClassName($A(this.classNames()).first() + '_disabled');
                this._disabled = true;
                disabledImageChange.call(this);
                createDisabledLayer.call(this);
                positionDisabledLayer.call(this);
                this.signalConnect('iwl:adjust', disableButton);
                return adjust.call(this);
            } else {
                this.removeClassName($A(this.classNames()).first() + '_disabled');
                this._disabled = false;
                defaultImageChange.call(this);
                removeDisabledLayer.call(this);
                this.signalDisconnect('iwl:adjust', disableButton);
                return adjust.call(this);
            }
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

        _init: function(id) {
            this.buttonParts = new Array;
            this.buttonImage = null;
            this.buttonLabel = null;
            this.buttonContent = null;
            this.options = Object.extend({
                size: 'default',
                disabled: false,
                submit: false,
                label: ''
            }, arguments[1] || {});
            this.loaded = false;
            this.cleanWhitespace();
            createElements.call(this);
            checkComplete.call(this);
            this.observe('mousedown', clickImageChange.bindAsEventListener(this));
            this.observe('mouseup', defaultImageChange.bindAsEventListener(this));
            if (this.options.disabled)
                this.setDisabled(true);
            if (this.options.submit)
                this.setSubmit.apply(this, Object.isArray(this.options.submit) ? this.options.submit : []);
            }
    }
})());

/* Deprecated */
var Button = IWL.Button;
