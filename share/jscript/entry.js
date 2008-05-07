// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.Entry is a class for adding entries
 * @extends IWL.Widget
 * */
IWL.Entry = Object.extend(Object.extend({}, IWL.Widget), (function() {
    var accumulator = function(a, n) { return a + parseFloat(n) };

    function adjust() {
        var children = [this.image1, this.control, this.image2].findAll(function(e) { return e != null });
        var width = children.invoke('getWidth').inject(0, accumulator)
            + (children.invoke('getStyle', 'marginLeft').inject(0, accumulator) || 0)
            + (children.invoke('getStyle', 'marginRight').inject(0, accumulator) || 0);
        this.setStyle({width: width + 1 + 'px'});
        this.style.visibility = '';
        this.emitSignal('iwl:load');
    }

    function clearButtonCallback() {
        this.control.value = '';
        this.control.focus();
    }

    function changeCallback() {
        if (!this.control.hasClassName($A(this.classNames()).first() + '_text_default'))
            this.value = this.control.value;
    }

    function setDefaultText() {
        if (!this.options.defaultText.empty()) {
            this.control.value = this.options.defaultText;
            this.control.addClassName($A(this.classNames()).first() + '_text_default');
        }
    }

    function defaultTextBlurCallback() {
        if (this.control.value === '')
            setDefaultText.call(this);
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
        if (!receiver)
            receiver = this.appendChild(new Element('div', {
                id: this.id + '_receiver', className: $A(this.classNames()).first() + '_receiver'
            }));
        this.autoCompleter = new Ajax.Autocompleter(this.control, receiver, url, options);
    }

    function periodicalChecker(element, callback, pe) {
        var dims = element.getDimensions();
        if (dims.width && dims.height) {
            pe.stop();
            callback();
        }
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
            if (Object.isUndefined(value) || value === null) value = '';
            this.control.value = value;
            this.value = this.control.value;
            if (this.value.empty())
                setDefaultText.call(this)
            else
                this.control.removeClassName($A(this.classNames()).first() + '_text_default');
            return this.emitSignal("iwl:change");
        },
        /**
         * @returns The current value of the entry 
         * @type Number 
         * */
        getValue: function() {
            return this.control.value === this.options.defaultText ? '' : this.control.value;
        },
        /**
         * Sets the default text value of the entry
         * @param {String} value The new default text of the entry
         * @returns The object
         * */
        setDefaultText: function(value) {
            this.options.defaultText = value;
            if (this.control.hasClassName($A(this.classNames()).first() + '_text_default'))
                setDefaultText.call(this)
            return this;
        },
        /*
         * @returns The default text of the entry
         * */
        getDefaultText: function() {
            return this.options.defaultText;
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

            var images = [this.image1, this.image2].findAll(function(e) { return e != null });
            if (this.control.getWidth() && this.control.getHeight()
                    && (!images.length || images.invoke('getWidth').concat(images.invoke('getHeight')).all()))
                adjust.call(this);
            else {
                var count = 0;
                var callback = function() {
                    if (--count == 0) adjust.call(this)
                }.bind(this);
                images.each(function(image) {
                    if (image.getWidth() && image.getHeight()) return;
                    count++;
                    if (image.complete)
                        new PeriodicalExecuter(periodicalChecker.bind(this, this.control, callback), 0.1);
                    else
                        image.signalConnect('load', function() {
                            new PeriodicalExecuter(periodicalChecker.bind(this, this.control, callback), 0.1)
                        }.bind(this));
                }.bind(this));
                if (!this.control.getWidth() || !this.control.getHeight()) {
                    count++;
                    new PeriodicalExecuter(periodicalChecker.bind(this, this.control, callback), 0.1);
                }
            }

            this.control.signalConnect('change', changeCallback.bind(this));
            changeCallback.call(this);
        }
    }
})());
