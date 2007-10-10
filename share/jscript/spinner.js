// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class Spinner is a class for adding entry spinners 
 * @extends Widget
 * */
var Spinner = {};
Object.extend(Object.extend(Spinner, Widget), (function() {
    var periodical_options = $H({border: 0.005, frequency: 0.5});

    function keyEventsCB(event) {
        var key_code = Event.getKeyCode(event);
    }

    function connectSpinnerSignals() {
        this.leftSpinner.signalConnect('mousedown', leftSpinnerMouseDown.bindAsEventListener(this));
        this.leftSpinner.signalConnect('mouseup', leftSpinnerMouseUp.bindAsEventListener(this));

        this.rightSpinner.signalConnect('mousedown', rightSpinnerMouseDown.bindAsEventListener(this));
        this.rightSpinner.signalConnect('mouseup', rightSpinnerMouseUp.bindAsEventListener(this));

        this.input.signalConnect('blur', inputBlur.bindAsEventListener(this));
        this.input.signalConnect('focus', inputFocus.bindAsEventListener(this));
        this.input.signalConnect('keypress', inputKeyPress.bindAsEventListener(this));
        this.input.signalConnect('keydown', inputKeyDown.bindAsEventListener(this));
        this.input.signalConnect('keyup', inputKeyUp.bindAsEventListener(this));

        this.signalConnect('mousedown', spinnerMouseDown.bindAsEventListener(this));
        Event.observe(document, "mousemove", documentMouseMove.bindAsEventListener(this));
        Event.observe(document, "mouseup", documentMouseUp.bindAsEventListener(this));
    }

    function leftSpinnerMouseDown(event) {
        if (this.periodical) {
            this.periodical.stop();
            this.periodical = null;
        }

        this.spinDirection = 'left';
        this.startSpinTime = new Date;
        this.speed = event.isLeftClick() ? event.shiftKey ?
            this.options.pageIncrement : this.options.stepIncrement : this.options.pageIncrement;
        spinnerPeriodical.call(this);
        this.periodical = new PeriodicalAccelerator(spinnerPeriodical.bind(this),
            periodical_options.merge({acceleration: this.options.acceleration}));
    }
    function leftSpinnerMouseUp(event) {
        if (this.periodical) {
            this.periodical.stop();
            this.periodical = null;
        }
        this.startSpinTime = null;
    }

    function rightSpinnerMouseDown(event) {
        if (this.periodical) {
            this.periodical.stop();
            this.periodical = null;
        }

        this.spinDirection = 'right';
        this.startSpinTime = new Date;
        this.speed = event.isLeftClick() ? event.shiftKey ?
            this.options.pageIncrement : this.options.stepIncrement : this.options.pageIncrement;
        spinnerPeriodical.call(this);
        this.periodical = new PeriodicalAccelerator(spinnerPeriodical.bind(this),
            periodical_options.merge({acceleration: this.options.acceleration}));
    }
    function rightSpinnerMouseUp(event) {
        if (this.periodical) {
            this.periodical.stop();
            this.periodical = null;
        }
        this.startSpinTime = null;
    }

    function spinnerPeriodical(pe) {
        var new_value = this.spinDirection == 'left' ? this.value - this.speed : this.value + this.speed;
        this.setValue(new_value);
    }

    function inputBlur(event) {
        this.input.removeClassName('spinner_text_selected');
        this.setValue(this.value);
    }
    function inputFocus(event) {
        this.input.addClassName('spinner_text_selected');
        var value = this.value;
        if (!isNaN(this.options.precision))
            value = value.toFixed(this.options.precision);
        this.input.value = value;
    }
    function inputKeyPress(event) {
        var value = this.input.value;
        value = value - 0;
        if (isNaN(value)) return;
        switch (Event.getKeyCode(event)) {
            case Event.KEY_RETURN:
                this.setValue(value);
                this.emitSignal("change");
            case Event.KEY_ESC:
                this.input.blur();
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
            this.startSpinTime = new Date;
            this.speed = event.shiftKey
                ? this.options.pageIncrement : this.options.stepIncrement;
            inputPeriodical.call(this);
            this.periodical = new PeriodicalAccelerator(inputPeriodical.bind(this),
                periodical_options.merge({acceleration: this.options.acceleration}));
        }
    }
    function inputKeyUp(event) {
        var key_code = Event.getKeyCode(event);
        if (key_code == Event.KEY_DOWN || key_code == Event.KEY_UP) {
            if (this.periodical) {
                this.periodical.stop();
                this.periodical = null;
            }
            this.startSpinTime = null;
        }
    }

    function inputPeriodical(pe) {
        var new_value = this.input.value - 0;
        new_value = this.spinDirection == 'left' ? new_value - this.speed : new_value + this.speed;
        new_value = wrapValue.call(this, new_value);
        if (!isNaN(new_value))
            this.input.value = new_value;
    }

    function wrapValue(number) {
        if (typeof number != 'number' || isNaN(number)) {
            if (this.options.snap)
                number = parseFloat(number) || 0;
            else return NaN;
        }
        if (isNaN(number)) return;

        if (this.options.wrap) {
            while (number < this.options.from)
                number = this.options.to + number + 1 - this.options.from;
            while (number > this.options.to)
                number = this.options.from + number - 1 - this.options.to;
        } else {
            if (number < this.options.from)
                number = this.options.from;
            else if (number > this.options.to)
                number = this.options.to;
        }

        return number;
    }

    function spinnerMouseDown(event) {
        this.dragging = true;
        this.dragStartPosition = event.pointerX();
    }

    function documentMouseMove(event) {
        if (!this.dragging) return;
        var x = event.pointerX()
        var offset = event.ctrlKey ? this.options.stepIncrement / this.options.pageIncrement :
        event.shiftKey ? this.options.pageIncrement : this.options.stepIncrement;
        var delta = (x - this.dragStartPosition) * offset;
        this.dragStartPosition = x;
        this.setValue(this.value + delta);
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

            this.value = number;
            if (!isNaN(this.options.precision))
                number = number.toFixed(this.options.precision);
            this.input.value = this.mask ? this.mask.evaluate({number: number}) : number;
            return this;
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
                acceleration: 0.1,
                snap: false,
                wrap: false,
                precision: false,
                mask: null
            }, arguments[1] || {});
            this.input = this.getElementsBySelector('.spinner_text')[0];
            this.leftSpinner = this.getElementsBySelector('.spinner_left')[0];
            this.rightSpinner = this.getElementsBySelector('.spinner_right')[0];
            this.range = $R(parseFloat(this.options.from) || 0, parseFloat(this.options.to) || 100);
            this.speed = this.options.stepIncrement;
            this.mask = null;
            this.dragging = false;
            if (this.options.mask && this.options.mask.match(/#\{number\}/))
                this.mask = new Template(this.options.mask);

            this.setValue(this.options.value);

            connectSpinnerSignals.call(this);
            keyLogEvent(this, keyEventsCB.bindAsEventListener(this));
            registerFocus(this);

            this.emitSignal('load');
        }
    }
})());
