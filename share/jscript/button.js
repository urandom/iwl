// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.Button is a class for creating buttons
 * @extends IWL.Widget
 * */
IWL.Button = Object.extend(Object.extend({}, IWL.Widget), (function () {
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

    function mouseOverCallback() {
        if (this._disabled) return;
        var className = $A(this.classNames()).first();
        this.addClassName(className + '_hover ' + className + '_' + this.options.size + '_hover')
    }

    function mouseOutCallback() {
        if (this._disabled) return;
        var className = $A(this.classNames()).first();
        this.removeClassName(className + '_hover ' + className + '_' + this.options.size + '_hover')
    }

    function mouseDownCallback() {
        if (this._disabled) return;
        var className = $A(this.classNames()).first();
        this.addClassName(className + '_press ' + className + '_' + this.options.size + '_press')
    }

    function mouseUpCallback() {
        if (this._disabled) return;
        var className = $A(this.classNames()).first();
        this.removeClassName(className + '_press ' + className + '_' + this.options.size + '_press')
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
            if (this._disabled)
                disableButton.call(this);
            return this;
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
                if (!this.buttonImage) {
                    var content = this.down('.button_content');
                    this.buttonImage = content.insertBefore(
                        Object.isElement(source)
                            ? source
                            : new Element('img', {
                                    src: source,
                                    id: this.id + '_image',
                                    className: 'image ' + $A(this.classNames()).first() + '_image'
                                }),
                        content.firstChild
                    );
                } else
                    this.buttonImage.src = source;
                this.buttonImage.complete
                    ? disableButton.call(this)
                    : this.buttonImage.observe('load', disableButton.bind(this));
            } else {
                this.buttonImage.remove();
                this.buttonImage = undefined;
                if (this._disabled)
                    disableButton.call(this);
            }
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
            if (!this.loaded)
                return this.signalConnect('iwl:load', this.setDisabled.bind(this, disabled));

            var className = $A(this.classNames()).first();
            if (disabled) {
                this._disabled = true;
                this.addClassName(className + '_disabled ' + className + '_' + this.options.size + '_disabled');
                createDisabledLayer.call(this);
                disableButton.call(this);
                return this;
            } else {
                this._disabled = false;
                this.removeClassName(className + '_disabled ' + className + '_' + this.options.size + '_disabled');
                removeDisabledLayer.call(this);
                return this;
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

        _init: function() {
            this.buttonImage = null;
            this.buttonLabel = null;
            this.options = Object.extend({
                size: 'default',
                disabled: false,
                submit: false,
                label: ''
            }, arguments[0] || {});
            this.buttonImage = $(this.id + '_image');
            this.buttonLabel = $(this.id + '_label');

            this.observe('mouseover', mouseOverCallback.bind(this));
            this.observe('mouseout', mouseOutCallback.bind(this));
            this.observe('mousedown', mouseDownCallback.bind(this));
            this.observe('mouseup', mouseUpCallback.bind(this));
            if (this.options.submit)
                this.setSubmit.apply(this, Object.isArray(this.options.submit) ? this.options.submit : []);
            this.loaded = true;
            this.emitSignal('iwl:load');
            if (this.options.disabled)
                this.setDisabled(true);
        }
    }
})());

/* Deprecated */
var Button = IWL.Button;
