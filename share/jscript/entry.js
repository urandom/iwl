// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.Entry is a class for adding entries
 * @extends IWL.Widget
 * */
IWL.Entry = Object.extend(Object.extend({}, IWL.Widget), (function() {
    var EntryCompleter = Class.create(Ajax.Autocompleter, {
        initialize: function(entry, update, url, options) {
            this.baseInitialize(entry.control, update, options);
            this.options.asynchronous  = true;
            this.options.onComplete    = this.onComplete.bind(this);
            this.options.defaultParams = this.options.parameters || null;
            this.url                   = url;
            this.entry                 = entry;
        },
        getUpdatedChoices: function() {
            this.entry.cancelCompletionRequest();

            this.startIndicator();

            var entry = encodeURIComponent(this.options.paramName) + '=' +
                encodeURIComponent(this.getToken());

            this.options.parameters = this.options.callback
                ? this.options.callback(this.element, entry)
                : entry;

            if(this.options.defaultParams)
                this.options.parameters += '&' + this.options.defaultParams;

            this.request = new Ajax.Request(this.url, this.options);
        }
    });

    function clearButtonCallback() {
        this.control.focus();
        setTextState.call(this, IWL.Entry.TextState.NORMAL, this.value = '');
    }

    function changeCallback(event, skip) {
        if (!skip && this.textState == IWL.Entry.TextState.NORMAL) {
            this.value = this.control.value;
            this.blurValue = null;
        }
    }

    function blurCallback() {
        this.focused = false;
        if (!Object.isString(this.value)) return;
        if (this.value.empty())
            setTextState.call(this, IWL.Entry.TextState.DEFAULT, this.defaultText);
        else if (this.blurValue !== null)
            setTextState.call(this, IWL.Entry.TextState.BLUR, this.blurValue);
        else
            setTextState.call(this, IWL.Entry.TextState.NORMAL, this.value);
    }

    function focusCallback() {
        this.focused = true;
        setTextState.call(this, IWL.Entry.TextState.NORMAL, this.value);
    }

    function keyUpCallback() {
        this.value = this.control.value;
    }

    function setupAutoComplete() {
        if (!Object.isArray(this.options.autoComplete) || !this.options.autoComplete[0])
            return;
        var url = this.options.autoComplete[0];
        var options = Object.extend({
            onShow: receiverOnShow.bind(this),
            onHide: receiverOnHide.bind(this)
        }, this.options.autoComplete[1]);
        this.receiver = $(this.id + '_receiver');
        if (!this.receiver) {
            this.receiver = new Element('div', {
                id: this.id + '_receiver', className: $A(this.classNames()).first() + '_receiver'
            });
            this.control.parentNode.appendChild(this.receiver);
        }
        this.autoCompleter = new EntryCompleter(this, this.receiver, url, options);
    }

    function receiverOnShow(element, update) {
        if(!update.style.position || update.style.position == 'absolute') {
            update.style.position = 'absolute';
            update.clonePosition(this, {
                setHeight: false,
                setWidth: false,
                offsetTop: this.offsetHeight
            });
            var padding = (parseFloat(update.getStyle('padding-left')) || 0) + (parseFloat(update.getStyle('padding-right')) || 0);
            var borders = (parseFloat(update.getStyle('border-left-width')) || 0) + (parseFloat(update.getStyle('border-right-width')) || 0);
            var thisWidth = this.getWidth() - padding - borders;
            if (update.getWidth() < thisWidth)
                update.style.width = thisWidth + 'px';
        }
        Effect.Appear(update,{duration:0.15});
    }

    function receiverOnHide(element, update) {
        new Effect.Fade(update, {
            duration: 0.15,
            afterFinish: function() {update.style.width = '';}
        });
    }

    function setTextState(state, value) {
        var className = $A(this.classNames()).first();
        this.control.removeClassName(className + '_text_default').removeClassName(className + '_text_blur');
        switch (state) {
            case IWL.Entry.TextState.DEFAULT:
                this.control.addClassName(className + '_text_default');
                if (value != '')
                    this.control.value = value;
                break;
            case IWL.Entry.TextState.BLUR:
                this.control.addClassName(className + '_text_blur');
                if (value != '')
                    this.control.value = value;
                break;
            default:
                this.control.value = value;
        }

        this.textState = state || IWL.Entry.TextState.NORMAL;
        this.emitSignal('iwl:text_state_change', state);
    }

    return {
        /**
         * Enables the auto-completing feature of the entry
         * @param {String} url The URL, from which the completion list will be requested
         * @param {Object} options The Ajax.Autocompleter options. See Scriptaculous Ajax.Autocompleter
         * @returns The object
         * */
        setAutoComplete: function(url) {
            if (this.autoCompleter) return;
            this.options.autoComplete = [url, arguments[1]];
            setupAutoComplete.call(this);
            return this;
        },
        /**
         * Cancels the current completion request, if any
         * @returns The object
         * */
        cancelCompletionRequest: function() {
            if (!this.autoCompleter) return this;
            if (this.autoCompleter.request && this.autoCompleter.request.transport)
                this.autoCompleter.request.transport.abort();
            this.receiver.hide();
            clearTimeout(this.autoCompleter.observer);
            return this;
        },
        /**
         * Sets the entry value
         * @param {String} value The new entry value
         * @param {String} blur The optional blur value
         * @returns The object
         * */
        setValue: function(value, blur) {
            if (Object.isUndefined(value) || value === null) value = '';
            value = value.toString();
            blur = value
                ? Object.isUndefined(blur) || blur === null
                    ? null
                    : blur.toString()
                : null;
            if (value.empty())
                setTextState.call(this, IWL.Entry.TextState.DEFAULT, this.defaultText);
            else if (!this.focused && blur !== null)
                setTextState.call(this, IWL.Entry.TextState.BLUR, blur);
            else
                setTextState.call(this, IWL.Entry.TextState.NORMAL, value);

            if (this.value == value && this.blurValue == blur) return;
            this.value = value;
            this.blurValue = blur;

            if (!this.__initFlag) {
                this.control.emitSignal('change', true);
                this.emitSignal("iwl:change");
            }
            
            return this;
        },
        /**
         * @returns The current value of the entry
         * @type String
         * */
        getValue: function() {
            return this.value;
        },

        /**
         * @returns The current blur value of the entry
         * @type String
         * */
        getBlurValue: function() {
            return this.blurValue;
        },
        /**
         * Sets the default text value of the entry
         * @param {String} value The new default text of the entry
         * @returns The object
         * */
        setDefaultText: function(value) {
            this.defaultText = value.toString();
            if (this.textState == IWL.Entry.TextState.DEFAULT)
                setTextState.call(this, IWL.Entry.TextState.DEFAULT, this.defaultText);
            return this;
        },
        /**
         * @returns The default text of the entry
         * */
        getDefaultText: function() {
            return this.defaultText;
        },
        /**
         * @returns One of the following:
         *          - IWL.Entry.TextState.DEFAULT: The entry's real value is empty and the entry is not focused
         *          - IWL.Entry.TextState.BLUR: The entry's blurred value is given, and the entry is blurred
         *          - IWL.Entry.TextState.NORMAL: The entry's real value is shown.
         * */
        getTextState: function() {
            return this.textState;
        },

        /**
         * Sets focus on the entry text field
         * @returns The object
         * */
        focus: function() {
            this.control.focus();
            return this;
        },
        /**
         * Removes focus on the entry text field
         * @returns The object
         * */
        blur: function() {
            this.control.blur();
            return this;
        },
        /**
         * @returns True, if the entry text field is focused
         * @type Boolean
         * */
        isFocused: function() {
            return this.focused;
        },
        /**
         * Selects the text inside the entry text field
         * @returns The object
         * */
        selectText: function() {
            this.control.select();
            return this;
        },

        _init: function(id) {
            this.options = Object.extend({
                clearButton: false,
                autoComplete: [],
                defaultText: '',
                blurValue: null
            }, arguments[1] || {});

            this.focused = false;
            this.cleanWhitespace();
            this.image1  = $(this.id + '_left');
            this.image2  = $(this.id + '_right');
            this.control = $(this.id + '_text');

            if (this.options.clearButton)
                this.image2.signalConnect('click', clearButtonCallback.bind(this));

            this.value = '', this.blurValue = null, this.defaultText = '';
            this.control.signalConnect('blur', blurCallback.bind(this));
            this.control.signalConnect('focus', focusCallback.bind(this));
            this.control.signalConnect('keyup', keyUpCallback.bind(this));
            this.control.signalConnect('change', changeCallback.bind(this));
            this.defaultText = this.options.defaultText.toString();

            this.__initFlag = true;
            this.setValue(this.control.value, this.options.blurValue);
            this.__initFlag = undefined;

            setupAutoComplete.call(this);

            changeCallback.call(this);
            this.emitSignal('iwl:load');
        }
    }
})());
IWL.Entry.TextState = (function () {
    var index = 0;

    return {
        DEFAULT: ++index,
        BLUR: ++index,
        NORMAL: ++index
    };
})();
