// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.Entry is a class for adding entries
 * @extends IWL.Widget
 * */
IWL.Entry = Object.extend(Object.extend({}, IWL.Widget), (function() {
    function clearButtonCallback() {
        this.control.value = '';
        this.control.focus();
    }

    function changeCallback() {
        if (!this.control.hasClassName($A(this.classNames()).first() + '_text_default'))
            this.value = this.control.value;
    }

    function defaultTextBlurCallback() {
        if (this.control.value === '') {
            this.control.value = this.options.defaultText;
            this.control.addClassName($A(this.classNames()).first() + '_text_default');
        }
    }

    function defaultTextFocusCallback() {
        if (this.control.value === this.options.defaultText) {
            this.control.value = '';
            this.control.removeClassName($A(this.classNames()).first() + '_text_default');
        }
    }

    function setupAutoComplete() {
        if (!Object.isArray(this.options.autoComplete) || !this.options.autoComplete[0])
            return;
        var url = this.options.autoComplete[0];
        var options = Object.extend({
            onShow: receiverOnShow.bind(this),
            onHide: receiverOnHide.bind(this)
        }, this.options.autoComplete[1]);
        var receiver = $(this.id + '_receiver');
        if (!receiver) {
            receiver = new Element('div', {
                id: this.id + '_receiver', className: $A(this.classNames()).first() + '_receiver'
            });
            this.control.parentNode.appendChild(receiver);
        }
        this.autoCompleter = new Ajax.Autocompleter(this.control, receiver, url, options);
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
         * Sets the entry value 
         * @param value The new entry value
         * @returns The object
         * */
        setValue: function(value) {
            this.value = this.control.value = value;
            return this.emitSignal("iwl:change");
        },
        /**
         * @returns The current value of the entry 
         * @type Number 
         * */
        getValue: function() {
            return this.control.value === this.options.defaultText ? '' : this.control.value;
        },

        _init: function(id) {
            this.options = Object.extend({
                clearButton: false,
                defaultText: false,
                autoComplete: []
            }, arguments[1] || {});

            this.cleanWhitespace();
            this.image1  = $(this.id + '_left');
            this.image2  = $(this.id + '_right');
            this.control = $(this.id + '_text');

            if (this.options.clearButton)
                this.image2.signalConnect('click', clearButtonCallback.bind(this));

            if (this.options.defaultText) {
                this.control.signalConnect('blur', defaultTextBlurCallback.bind(this));
                this.control.signalConnect('focus', defaultTextFocusCallback.bind(this));
                if (!this.control.value)
                    this.control.value = this.options.defaultText;
            }
            setupAutoComplete.call(this);

            this.control.signalConnect('change', changeCallback.bind(this));
            changeCallback.call(this);
        }
    }
})());
