// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.ProgressBar is a class for adding progress bars
 * @extends IWL.Widget
 * */
IWL.ProgressBar = Object.extend(Object.extend({}, IWL.Widget), (function() {
    var dp100d = 0.02;

    function updateLabel() {
        if (!this.text) return;
        this.label.update(this.text.evaluate({
            percent: this.pulsating ? null : (this.value * 100).toFixed(0) + '%'
        }));
    }

    function updateBlock() {
        this.block.style.width = this.value * 100 + '%';
    }

    function shake(distance) {
        if (this.pulsating)
            (function() {
                new Effect.Pulsate(this.block, {distance: distance, duration: distance * dp100d, afterFinish: shake.bind(this, distance)});
            }).bind(this).delay(0.25);
        else
            updateBlock.call(this);
    }

    function normalizeValue(value) {
        value = parseFloat(value);
        if (value > 1) value = 1;
        else if (value < 0 || !value) value = 0;
        return value;
    }

    return {
        /**
         * Sets the value of the progress bar
         * @param {Float} value The progress bar value, between 0 and 1
         * @returns The object
         * */
        setValue: function(value) {
            this.value = normalizeValue(value);
            if (this.pulsating)
                this.setPulsate(false);
            else
                updateBlock.call(this);
            updateLabel.call(this);
            return this.emitSignal("iwl:change");
        },
        /**
         * @returns The current value of the progress bar
         * @type Number 
         * */
        getValue: function() {
            return this.value;
        },
        /**
         * Sets the text of the progress bar
         * @param {String} text The string, which will be displayed inside the progress bar.
         *                      Any "#{percent}" will be replaced by the percentage value of the progress bar.
         * @returns The object
         * */
        setText: function(text) {
            this.text = new Template(text);
            updateLabel.call(this);

            return this;
        },
        /**
         * @returns The current text of the progress bar
         * @type String 
         * */
        getText: function() {
            return this.text.template;
        },
        /**
         * Sets whether the progress bar is pulsating
         * @param {Boolean} pulsate If true, the progress bar should pulsate
         * @returns The object
         * */
        setPulsate: function(pulsate) {
            if (pulsate) {
                var size = parseFloat(this.getStyle('width') || 0);
                this.block.setStyle({width: size * 0.1 + 'px'});
                this.pulsating = true;
                shake.call(this, size * 0.9);
            } else {
                this.pulsating = false;
            }
            return this;
        },
        /**
         * @returns Returns whether the progress bar is pulsating
         * @type Boolean
         * */
        isPulsating: function() {
            return this.pulsating;
        },

        _init: function(id) {
            this.options = Object.extend({
                opacity: 0.7,
                value: 0.0,
                text: '',
                pulsate: false
            }, arguments[1] || {});

            this.cleanWhitespace();

            var className = $A(this.classNames()).first();
            this.block = this.select('.' + className + '_block').first();
            this.label = this.select('.' + className + '_label').first();

            this.setValue(this.options.value);
            this.setText(this.options.text);

            if (this.options.pulsate)
                this.setPulsate(this.options.pulsate);

            this.block.setOpacity(this.options.opacity);

            this.emitSignal('iwl:load');
        }
    }
})());
