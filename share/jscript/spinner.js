// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.Spinner is a class for adding entry spinners 
 * @extends IWL.Widget
 * */
IWL.Spinner = Object.extend(Object.extend({}, IWL.Widget), (function() {
    var periodical_options = {border: 0.005, frequency: 0.5};

    function keyEventsCB(event) {
        var key_code = Event.getKeyCode(event);
    }

    function connectSpinnerSignals() {
        mouseOutEvent = spinnerMouseOut.bindAsEventListener(this);

        this.leftSpinner.signalConnect('mousedown', leftSpinnerMouseDown.bindAsEventListener(this));
        this.leftSpinner.signalConnect('mouseup', leftSpinnerMouseUp.bindAsEventListener(this));
        this.leftSpinner.signalConnect('mouseout', mouseOutEvent);

        this.rightSpinner.signalConnect('mousedown', rightSpinnerMouseDown.bindAsEventListener(this));
        this.rightSpinner.signalConnect('mouseup', rightSpinnerMouseUp.bindAsEventListener(this));
        this.rightSpinner.signalConnect('mouseout', mouseOutEvent);

        this.control.signalConnect('blur', inputBlur.bindAsEventListener(this));
        this.control.signalConnect('focus', inputFocus.bindAsEventListener(this));
        this.control.signalConnect('keypress', inputKeyPress.bindAsEventListener(this));
        this.control.signalConnect('keydown', inputKeyDown.bindAsEventListener(this));
        this.control.signalConnect('keyup', inputKeyUp.bindAsEventListener(this));

        this.control.signalConnect('mousedown', spinnerMouseDown.bindAsEventListener(this));
        Event.observe(document, "mousemove", documentMouseMove.bindAsEventListener(this));
        Event.observe(document, "mouseup", documentMouseUp.bindAsEventListener(this));
    }

    function leftSpinnerMouseDown(event) {
        if (this.periodical) {
            this.periodical.stop();
            this.periodical = null;
        }

        this.spinDirection = 'left';
        this.speed = event.isLeftClick() ? event.shiftKey ?
            this.options.pageIncrement : this.options.stepIncrement : this.options.pageIncrement;
        this.periodical = new PeriodicalAccelerator(spinnerPeriodical.bind(this),
            Object.extend(periodical_options, {acceleration: this.options.acceleration}));
        spinnerPeriodical.call(this);
    }
    function leftSpinnerMouseUp(event) {
        stopSpinning.call(this);
    }

    function rightSpinnerMouseDown(event) {
        if (this.periodical) {
            this.periodical.stop();
            this.periodical = null;
        }

        this.spinDirection = 'right';
        this.speed = event.isLeftClick() ? event.shiftKey ?
            this.options.pageIncrement : this.options.stepIncrement : this.options.pageIncrement;
        this.periodical = new PeriodicalAccelerator(spinnerPeriodical.bind(this),
            Object.extend(periodical_options, {acceleration: this.options.acceleration}));
        spinnerPeriodical.call(this);
    }
    function rightSpinnerMouseUp(event) {
        stopSpinning.call(this);
    }

    function spinnerMouseOut(event) {
        if (this.dragging) return;
        stopSpinning.call(this);
    }

    function stopSpinning() {
        if (this.periodical) {
            this.periodical.stop();
            this.periodical = null;
        }
    }

    function spinnerPeriodical(pe) {
        var new_value = this.spinDirection == 'left' ? this.preciseValue - this.speed : this.preciseValue + this.speed;
        this.setValue(new_value);
    }

    function inputBlur(event) {
        this.control.removeClassName('spinner_text_selected');
        this.setValue(this.preciseValue);
    }
    function inputFocus(event) {
        this.control.addClassName('spinner_text_selected');
        var value = this.preciseValue;
        if (Object.isNumber(this.options.precision) && !isNaN(this.options.precision))
            value = value.toFixed(this.options.precision);
        this.control.value = value;
    }
    function inputKeyPress(event) {
        var value = this.control.value;
        value = value - 0;
        if (isNaN(value)) return;
        switch (Event.getKeyCode(event)) {
            case Event.KEY_RETURN:
                this.setValue(value);
            case Event.KEY_ESC:
                this.control.blur();
                break;
            default:
                break;
        }
    }
    function inputKeyDown(event) {
        var key_code = Event.getKeyCode(event);
        if (key_code == Event.KEY_DOWN || key_code == Event.KEY_UP) {
            if (this.periodical) {
                this.periodical.stop();
                this.periodical = null;
            }

            this.spinDirection = key_code == Event.KEY_DOWN ? 'left' : 'right';
            this.speed = event.shiftKey
                ? this.options.pageIncrement : this.options.stepIncrement;
            this.periodical = new PeriodicalAccelerator(inputPeriodical.bind(this),
                Object.extend(periodical_options, {acceleration: this.options.acceleration}));
            inputPeriodical.call(this);
        }
    }
    function inputKeyUp(event) {
        var key_code = Event.getKeyCode(event);
        if (key_code == Event.KEY_DOWN || key_code == Event.KEY_UP) {
            if (this.periodical) {
                this.periodical.stop();
                this.periodical = null;
            }
        }
    }

    function inputPeriodical(pe) {
        var new_value = this.control.value - 0;
        new_value = this.spinDirection == 'left' ? new_value - this.speed : new_value + this.speed;
        new_value = wrapValue.call(this, new_value);
        if (!isNaN(new_value)) {
            if (Object.isNumber(this.options.precision) && !isNaN(this.options.precision))
                new_value = new_value.toFixed(this.options.precision);
            this.control.value = new_value;
        }
    }

    function wrapValue(number) {
        if (!Object.isNumber(number) || isNaN(number)) {
            if (this.options.snap)
                number = parseFloat(number) || 0;
            else return NaN;
        }
        if (isNaN(number)) return;

        if (this.options.wrap) {
            while (number < this.from)
                number = this.to + number + 1 - this.from;
            while (number > this.to)
                number = this.from + number - 1 - this.to;
        } else {
            if (number < this.from)
                number = this.from;
            else if (number > this.to)
                number = this.to;
        }

        return number;
    }

    function spinnerMouseDown(event) {
        this.dragging = true;
        this.dragStartPosition = event.pointerX();
    }

    function documentMouseMove(event) {
        if (!this.dragging) return;
        var x = event.pointerX();
        var offset = event.ctrlKey ? this.options.stepIncrement / this.options.pageIncrement :
        event.shiftKey ? this.options.pageIncrement : this.options.stepIncrement;
        var delta = (x - this.dragStartPosition) * offset;
        this.dragStartPosition = x;
        this.setValue(this.preciseValue + delta);
    }

    function documentMouseUp(event) {
        this.dragging = false;
        this.dragStartPosition = 0;
    }

    return {
        /**
         * Sets the spinner value 
         * @param {Number} number The new spinner value
         * @returns The object
         * */
        setValue: function(number) {
            number = wrapValue.call(this, number);
            if (isNaN(number)) return;

            this.preciseValue = number;
            if (Object.isNumber(this.options.precision) && !isNaN(this.options.precision))
                number = number.toFixed(this.options.precision);
            this.value = parseFloat(number);
            this.control.value = this.mask ? this.mask.evaluate({number: number}) : number;
            this.control.emitSignal("change", true);
            return this.emitSignal("iwl:change");
        },
        /**
         * @returns The current value of the spinner 
         * @type Number 
         * */
        getValue: function() {
            return this.value;
        },

        _init: function() {
            this.options = Object.extend({
                value: 0,
                from: 0,
                to: 100,
                stepIncrement: 1.0,
                pageIncrement: 10.0,
                acceleration: 0.2,
                snap: false,
                wrap: false,
                precision: false,
                mask: null
            }, arguments[0] || {});
            this.input = this.control = this.select('.spinner_text')[0];
            this.leftSpinner = this.select('.spinner_left')[0];
            this.rightSpinner = this.select('.spinner_right')[0];
            this.speed = this.options.stepIncrement;
            this.mask = null;
            this.dragging = false;
            this.from = parseFloat(this.options.from);
            this.to = parseFloat(this.options.to);
            if (isNaN(this.from)) this.from = -Infinity;
            if (isNaN(this.to)) this.to = Infinity;
            if (this.options.mask && this.options.mask.match(/#\{number\}/))
                this.mask = new Template(this.options.mask);

            this.setValue(this.options.value);

            connectSpinnerSignals.call(this);
            this.keyLogger(keyEventsCB.bindAsEventListener(this));
            this.registerFocus();

            this.loaded = true;
            this.emitSignal('iwl:load');
        }
    }
})());

/* Deprecated */
var Spinner = IWL.Spinner;
