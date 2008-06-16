// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.NavBar is a class for adding navigation bars
 * @extends IWL.Widget
 * */
IWL.NavBar = Object.extend(Object.extend({}, IWL.Widget), (function() {
    return {
        /**
         * Activates the given path 
         * @param path The path to activate.
         * @returns The object
         * */
        activatePath: function(path) {
            if (!(path = $(path))) return;
            var paths = [];
            var values = [];

            do {
                paths.push(path.getText());
                values.push(path.getValue());
            } while (path = path.prevPath());

            paths = paths.reverse();
            values = values.reverse();
            this.emitSignal('iwl:activate_path', paths, values);
            this.emitEvent('IWL-NavBar-activatePath', {path: paths, values: values});
            return this;
        },
        _init: function() {
            var className = $A(this.classNames()).first();
            this.crumbs = this.select('.' + className + '_crumb').map(
                function(path) { return IWL.NavBar.Path.create(path, this) }.bind(this)
            );
            this.combo = IWL.NavBar.Path.create(this.id + '_combo', this);

            this.loaded = true;
            this.emitSignal('iwl:load');
        }
    }
})());

/**
 * @class IWL.NavBar.Path is a class for adding path elements to a navigation bar
 * @extends IWL.Widget
 * */
IWL.NavBar.Path = Object.extend(Object.extend({}, IWL.Widget), (function() {
    return {
        /**
         * @returns The previous path
         * */
        prevPath: function() {
            if (this == this.navbar.crumbs.first()) return;
            if (this.isCombo) return this.navbar.crumbs.last();
            return this.navbar.crumbs[this.navbar.crumbs.indexOf(this) - 1];
        },
        /**
         * @returns The next path
         * */
        nextPath: function() {
            if (this.isCombo) return;
            if (this == this.navbar.crumbs.last()) return this.navbar.combo;
            return this.navbar.crumbs[this.navbar.crumbs.indexOf(this) + 1];
        },
        /**
         * Sets the path value 
         * @param value The new path value
         * @returns The object
         * */
        setValue: function(value) {
            this.isCombo ? this.value = value : this.writeAttribute('iwl:value', value);
            return this.emitSignal("iwl:change");
        },
        /**
         * @returns The current value of the path 
         * @type String
         * */
        getValue: function() {
            return this.isCombo ? this.value : this.readAttribute('iwl:value');
        },
        /**
         * @returns The current text of the path 
         * @type String
         * */
        getText: function() {
            return Element.getText(this.isCombo ? this.options[this.selectedIndex] : this);
        },
        _init: function(navbar) {
            this.navbar = navbar;
            this.isCombo = this.hasClassName('combo');

            this.isCombo
                ? this.signalConnect('change', this.navbar.activatePath.bind(this.navbar, this))
                : this.signalConnect('click', function() {
                        this.navbar.combo.selectedIndex = 0;
                        this.navbar.activatePath(this)
                  }.bind(this));
        }
    }
})());
