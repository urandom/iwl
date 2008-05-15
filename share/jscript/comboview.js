// vim: set autoindent shiftwidth=4 tabstop=8:
IWL.ComboView = Object.extend(Object.extend({}, IWL.Widget), (function () {
    function connectButtonSignals() {
        this.button.signalConnect('mouseover', function() {
            setState.call(this, this.state | IWL.ComboView.State.HOVER);
        }.bind(this));
        this.button.signalConnect('mouseout', function() {
            setState.call(this, this.state & IWL.ComboView.State.HOVER);
        }.bind(this));
    }

    function setState(state) {
        this.state = state;
        var classNames = ['comboview_button'];
        if (state = IWL.ComboView.State.ON | IWL.ComboView.State.HOVER) {
            classNames.push('comboview_button_on_hover');
        } else if (state = IWL.ComboView.State.ON | IWL.ComboView.State.PRESS) {
            classNames.push('comboview_button_on_press');
        } else if (state = IWL.ComboView.State.ON) {
            classNames.push('comboview_button_on');
        } else if (state = IWL.ComboView.State.OFF | IWL.ComboView.State.HOVER) {
            classNames.push('comboview_button_off_hover');
        } else if (state = IWL.ComboView.State.OFF | IWL.ComboView.State.PRESS) {
            classNames.push('comboview_button_off_press');
        } else if (state = IWL.ComboView.State.OFF) {
            classNames.push('comboview_button_off');
        }
        this.button.className = classNames.join(' ');
        this.emitSignal('iwl:state_change', state);
    }

    return {
        _init: function(id, model) {
            this.options = Object.extend({}, arguments[2]);
            this.model = model;
            this.button = this.down('.comboview_button');
            this.content = this.down('.comboview_content');

            connectButtonSignals.call(this);

            this.state = IWL.ComboView.State.OFF;
            this.emitSignal('iwl:load');
        }
    }
})());

IWL.ComboView.State = (function () {
    var index = 0;

    return {
        HOVER: 1 << index++,
        PRESS: 1 << index++,
        OFF: 1 << index++,
        ON: 1 << index++
    }
})();
