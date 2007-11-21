// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.Menu is a class for adding menus
 * @extends IWL.Widget
 * */
IWL.Menu = Object.extend(Object.extend({}, IWL.Widget), (function () {
    function bindPop(event, parentItem) {
        if (parentItem)
            this.parentItem = $(parentItem);
        if (this.popped)
            this.popDown();
        else
            this.popUp();
        IWL.Focus.current = this;
        Event.stop(event);
        return this;
    }

    function removeQuirks() {
        if (!Prototype.Browser.IE || Prototype.Browser.IE7) return;
        if (this.__qframe) return;
        var dims = Element.getDimensions(this);
        var qframe = new Element('iframe', {
            src: "javascript: false", className: "qframe",
            style: "width: " + dims.width + "px; height: " + dims.height + "px;"
        });
        var mi_top = parseFloat(this.getStyle('top') || 0)
        if (this.hasClassName('submenu') && mi_top > 0)
            mi_top -= this.menuItems[0].getDimensions().height;
        var style = {left: this.getStyle('left'), top: mi_top + "px"};
        Element.setStyle(qframe, style);
        this.up().insertBefore(qframe, this);
        this.__qframe = $(qframe);
    }

    function setupScrolling() {
        var width = this.getStyle('width');
        var height = this.getStyle('height');
        if (this.options.maxHeight > parseFloat(height)) return;
        var new_width = parseInt(width) + 20;
        this.addClassName('scrolling_menu');
        if (Prototype.Browser.Opera)
            this.setStyle({width: new_width + 'px', height: this.options.maxHeight + 'px', overflow: 'auto'});
        else
            this.setStyle({width: new_width + 'px', height: this.options.maxHeight + 'px', overflowY: 'scroll'});
    }

    function focus(element) {
        if (!(element = $(element))) return;
        return (function() {IWL.Focus.current = element}).defer();
    }

    function keyEventsCB(event) {
        var key_code = Event.getKeyCode(event);
        var shift = event.shiftKey;
        var ctrl = event.ctrlKey;

        if (key_code == Event.KEY_LEFT) {
            Event.stop(event);

            if (this.hasClassName('menubar')) {
                this.selectItem(this.getPrevMenuItem() || this.menuItems.last());
            } else {
                if (this.parentMenu) {
                    this.unselectItem();
                    if (this.parentMenu.hasClassName('menubar'))
                        this.parentMenu.selectItem(
                            this.parentMenu.getPrevMenuItem() || this.parentMenu.menuItems.last());
                    focus(this.parentMenu)
                }
            }
        } else if (key_code == Event.KEY_UP)  {
            Event.stop(event);

            if (this.hasClassName('menubar') && this.currentItem) {
                var submenu = this.currentItem.submenu;
                if (!submenu) return;
                submenu.selectItem(submenu.menuItems.last());
                focus(submenu)
            } else {
                var select = this.getPrevMenuItem() || this.menuItems.last();
                this.selectItem(select);
                if (this.options.maxHeight)
                    new Effect.ScrollElement(select, this, {duration: 0.3});
            }
        } else if (key_code == Event.KEY_RIGHT) {
            Event.stop(event);

            if (this.hasClassName('menubar')) {
                this.selectItem(this.getNextMenuItem() || this.menuItems[0]);
            } else {
                if (this.currentItem && this.currentItem.submenu) {
                    var submenu = this.currentItem.submenu;
                    submenu.selectItem(submenu.menuItems[0]);
                    focus(submenu)
                } else if (this.parentMenu && this.parentMenu.hasClassName('menubar')) {
                    this.parentMenu.selectItem(
                        this.parentMenu.getNextMenuItem() || this.parentMenu.menuItems[0]);
                    focus(this.parentMenu)
                }
            }
        } else if (key_code == Event.KEY_DOWN) {
            Event.stop(event);

            if (this.hasClassName('menubar') && this.currentItem) {
                var submenu = this.currentItem.submenu;
                if (!submenu) return;
                submenu.selectItem(submenu.menuItems[0]);
                focus(submenu)
            } else {
                var select = this.getNextMenuItem() || this.menuItems[0];
                this.selectItem(select);
                if (this.options.maxHeight)
                    new Effect.ScrollElement(select, this, {duration: 0.3});
            }
        } else if (key_code == Event.KEY_RETURN) {
            Event.stop(event);

            if (this.currentItem) {
                this.currentItem.toggle();
                this.currentItem.activate();
            }
            this.popDownRecursive();
        } else if (key_code == Event.KEY_ESC) {
            Event.stop(event);

            this.popDownRecursive();
        } else if (key_code = Event.KEY_SPACE) {
            if (this.currentItem) {
                Event.stop(event);
                this.currentItem.toggle();
            } 
        }
    }

    return {
        /**
         * Pops up (shows) the menu
         * @returns The object
         * */
        popUp: function() {
            if (this.popped) return;
            if (this.hasClassName('menubar')) return;
            this.setStyle({display: 'block', visibility: 'hidden'});
            if (this.parentMenu)
                this.parentMenu.poppedChild = this;
            this.popped = true;
            if (this.__qframe) this.__qframe.show();

            if (this.parentItem && !this.positioned) {
                var paren_position;
                if (this.parentMenu && !this.parentMenu.hasClassName('menubar'))
                    this.parentMenu.setStyle({display: 'block'});
                if (this.parentMenu && this.parentMenu.getStyle('position') == 'absolute')
                    paren_position = this.parentItem.cumulativeOffset();
                else
                    paren_position = this.parentItem.positionedOffset();
                var paren_dimensions = this.parentItem.getDimensions();
                if (this.hasClassName('submenu')) {
                    Element.setStyle(this, {left: paren_dimensions.width + 'px'});
                } else {
                    Element.setStyle(this, {left: paren_position[0] + 'px',
                            top: paren_position[1] + paren_dimensions.height + 'px'});
                }
                if (this.options.maxHeight)
                    setupScrolling.call(this);
                if (Prototype.Browser.IE) {
                    var dims = this.getDimensions();
                    this.setStyle({width: dims.width + 'px', height: dims.height + 'px'});
                }
//                removeQuirks.call(this);
                this.positioned = true;
            }
            return this.setStyle({visibility: 'visible'});
        },
        /**
         * Pops down (hides) the menu
         * @returns The object
         * */
        popDown: function() {
            if (this.poppedChild)
                this.poppedChild.popDown();
            this.unselectItem();
            if (!this.popped) return;
            if (this.hasClassName('menubar')) return;
            if (this.__qframe) this.__qframe.hide();
            this.style.display = 'none';
            if (this.parentMenu) {
                this.parentMenu.poppedChild = null;
                focus(this.parentMenu);
            }
            this.popped = false;
            return this;
        },
        /**
         * If the menu is popped up, it is hidden, else, it is shown
         * @returns The object
         * */
        toggle: function() {
            if (this.popped)
                return this.popDown();
            else
                return this.popUp();
        },
        /**
         * Pops down the menu and all its child menus.
         * @returns The object
         * */
        popDownRecursive: function() {
            this.popDown();
            if (this.parentMenu)
                this.parentMenu.popDownRecursive();
            return this;
        },
        /**
         * Binds the menu to an element. If the element emits the given signal, the menu is popped up
         * @param element The element to bind to
         * @param signal The signal name
         * @returns The object
         * */
        bindToWidget: function(element, signal) {
            if (!(element = $(element))) return;
            element.signalConnect(signal, bindPop.bindAsEventListener(this, element));
            return this;
        },
        /**
         * Selects the given menu item 
         * @param item The menu item to select.
         * @returns The object
         * */
        selectItem: function(item) {
            if (!(item = $(item))) return;
            item.setSelected(true);
            return this;
        },
        /**
         * Unelects the given menu item 
         * @param item The menu item to unselect.
         * @returns The object
         * */
        unselectItem: function(item) {
            if (!(item = $(item)) && !(item = this.currentItem))
                return;
            item.setSelected(false);
            return this;
        },
        /**
         * @returns The currently selected menu item 
         * */
        getSelectedMenuItem: function() {
            return this.currentItem;
        },
        /**
         * Returns the previous menu item
         * @param {IWL.Menu.Item} item The reference menu item. If none is given, the current one is used.
         * @returns The previous menu item
         * */
        getPrevMenuItem: function(item) {
            if (!(item = $(item)) && !(item = this.currentItem))
                return;

            var index = this.menuItems.indexOf(item);
            var last = this.menuItems.length - 1;
            if (index == -1) return;
            var new_item = index == 0 ? this.menuItems[last] : this.menuItems[index - 1];

            return new_item;
        },
        /**
         * Returns the next menu item
         * @param {IWL.Menu.Item} item The reference menu item. If none is given, the current one is used.
         * @returns The next menu item
         * */
        getNextMenuItem: function(item) {
            if (!(item = $(item)) && !(item = this.currentItem))
                return;

            var index = this.menuItems.indexOf(item);
            var last = this.menuItems.length - 1;
            if (index == -1) return;
            var new_item = index == last ? this.menuItems[0] : this.menuItems[index + 1];

            return new_item;
        },
        /**
         * Toggles the check or radio menu item
         * @param item The menu item to toggle
         * @returns The object
         * */
        toggleItem: function(item) {
            if (!(item = $(item))) return;
            item.toggle();
            return this;
        },

        _init: function(id) {
            this.menuItems = [];
            this.parentItem = null;
            this.parentMenu = null;
            this.poppedChild = null;
            this.popped = false;
            this.positioned = false;
            this.options = Object.extend({
                mouseOverActivation: false,
                maxHeight: 0,
                popDownTimeout: 500
            }, arguments[1] || {});

            this.childElements().each(function ($_) {
                if ($_.tagName == 'LI'
                    && ($_.hasClassName('menubar_item')
                        || $_.hasClassName('menu_item')))
                    this.menuItems.push(IWL.Menu.Item.create($_, this));
            }.bind(this));

            var paren = this.up();
            while (paren) {
                if (paren.className) {
                    if (paren.hasClassName('menu_item') || paren.hasClassName('menubar_item')) {
                        this.parentItem = paren;
                        break;
                    }
                }
                if (paren === document) break;
                paren = paren.up();
            }
            while (paren) {
                if (paren.className) {
                    if (paren.hasClassName('menubar') || paren.hasClassName('menu')) {
                        this.parentMenu = paren;
                        break;
                    }
                }
                if (paren === document) break;
                paren = paren.up();
            }
            this.registerFocus();
            Event.observe(window, 'click', function(event) {
                if (!Event.checkElement(event, this))
                    this.popDown();
            }.bind(this));
            Event.observe(document.body, 'click', function(event) {
                if (!Event.checkElement(event, this))
                    this.popDown();
            }.bind(this));
            this.keyLogger(keyEventsCB.bindAsEventListener(this));
        }
    }
})());

/**
 * @class IWL.Menu.Item is a class for menu items
 * @extends IWL.Widget
 * */
IWL.Menu.Item = Object.extend(Object.extend({}, IWL.Widget), (function () {
    function toggleCheckItem() {
	if (!this.hasClassName('menu_check_item') || this.isNotEnabled()) return;
	if (this.hasClassName('menu_check_item_checked')) {
	    this.checked = false;
	    this.removeClassName('menu_check_item_checked');
	} else {
	    this.checked = true;
	    this.addClassName('menu_check_item_checked');
	}
	this.emitSignal('iwl:change');
	return this;
    }

    function toggleRadioItem() {
	var paren = this.up();
	
        if (!this.hasClassName('menu_radio_item') || this.isNotEnabled()) return;
	if (this.hasClassName('menu_radio_item_checked')) return;
	paren.childElements().each(function($_) {
	    if (this.name) {
		if ($_.name == this.name) {
		    if ($_.checked) {
			$_.checked = false;
			$_.removeClassName('menu_radio_item_checked');
		    }
		}
	    } else {
		if ($_.checked) {
		    $_.checked = false;
		    $_.removeClassName('menu_radio_item_checked');
		}
	    }
	}.bind(this));
	this.checked = true;
	this.addClassName('menu_radio_item_checked');
	this.emitSignal('iwl:change');
	return this;
    }

    function initEvents() {
	if (this.menu.hasClassName('menubar')) {
	    if (!this.menu.options.mouseOverActivation) {
		if (this.submenu) {
		    this.observe('click', function(event) {
                        this.setSelected(!this.isSelected());
			Event.stop(event);
		    }.bind(this));
		    this.observe('mouseover', function(event) {
			if (!this.menu.poppedChild || this.menu.poppedChild == this.submenu)
			    return;
			this.setSelected(true);
			Event.stop(event);
		    }.bind(this));
		}
	    } else {
		this.observe('mouseover', this.setSelected.bind(this, true));
	    }
	    return;
	}
	if (this.submenu) {
	    this.observe('mouseover', function() {
		if (this.__pop_timeout)
		    clearTimeout(this.__pop_timeout);
		this.__pop_timeout = null;
		this.submenu.popUp();
	    }.bind(this));
	    this.observe('mouseout', function() {
		if (this.__pop_timeout)
		    clearTimeout(this.__pop_timeout);
		this.__pop_timeout = setTimeout(this.submenu.popDown.bind(this.submenu),
		    this.menu.options.popDownTimeout);
	    }.bind(this));
	}
	this.observe('click', function(event) {
	    this.menu.popDownRecursive();
	    Event.stop(event);
	}.bind(this));
        this.observe('dblclick', this.activate.bind(this));
        this.observe('mouseover', this.setSelected.bind(this, true));
	if (this.hasClassName('menu_check_item'))
	    this.observe('click', toggleCheckItem.bind(this));
	else if (this.hasClassName('menu_radio_item'))
	    this.observe('click', toggleRadioItem.bind(this));
    }

    function checked() {
	if (this.hasClassName('menu_radio_item'))
	    return this.hasClassName('menu_radio_item_checked');
	else if (this.hasClassName('menu_check_item'))
	    return this.hasClassName('menu_check_item_checked');
    }

    return {
        /**
         * Sets whether the menu item is selected
         * @param {Boolean} select True if the item should be selected
         * @returns The object
         * */
        setSelected: function(select) {
            if (this.isNotEnabled()) return;
            if (select) {
                if (this.isSelected()) return;
                if (this.menu.currentItem)
                    this.menu.currentItem.setSelected(false);
                if (this.menu.hasClassName('menubar'))
                    this.addClassName('menubar_item_selected');
                else
                    this.addClassName('menu_item_selected');
                this.menu.currentItem = this;
                if (this.submenu)
                    this.submenu.popUp();

                this.emitSignal('iwl:select');
            } else {
                if (!this.isSelected()) return;
                if (this.menu.currentItem == this)
                    this.menu.currentItem = null;
                this.removeClassName('menu_item_selected').removeClassName('menubar_item_selected');
                if (this.submenu)
                    this.submenu.popDown();

                this.emitSignal('iwl:unselect');
            }
            return this;
        },
        /**
         * @returns True if the menu item is selected
         * @type Boolean
         * */
        isSelected: function() {
            if (this.menu.hasClassName('menubar'))
                return this.hasClassName('menubar_item_selected');
            else return this.hasClassName('menu_item_selected');
        },
        /**
         * Sets whether the menu item is disabled 
         * @param {Boolean} disable True if the item should be disabled 
         * @returns The object
         * */
        setDisabled: function(disable) {
            disable ? this.addClassName('menu_item_disabled') : this.removeClassName('menu_item_disabled');
            return this;
        },
        /**
         * @returns True if the menu item is disabled 
         * @type Boolean
         * Note: isDisabled is a read-only attribute in Internet Explorer
         * */
        isNotEnabled: function() {
            return this.hasClassName('menu_item_disabled');
        },
        /**
         * Sets the given menu to be the submenu for the menu item
         * @param submenu The menu to attach as a submenu
         * @returns The object
         * */
        setSubmenu: function(submenu) {
            if (this.submenu) {
                this.removeChild(this.submenu);
                delete this.submenu;
            }

            if (submenu) {
                this.appendChild(submenu);
                if (!this.hasClassName('menubar_item_label')) {
                    this.firstChild.addClassName('menu_item_label_parent');
                }
            }
        },
        /**
         * Toggles the value of the check or radio menu item
         * @returns The object
         * */
        toggle: function() {
            if (this.hasClassName('menu_check_item')) {
                return toggleCheckItem.call(this);
            } else if (this.hasClassName('menu_radio_item')) {
                return toggleRadioItem.call(this);
            }
        },
        /**
         * Activates the menu item
         * @returns The object
         * */
        activate: function() {
            if (this.isNotEnabled()) return;
            this.menu.emitSignal('iwl:menu_item_activate', this);
            return this.emitSignal('iwl:activate');
        },

        _init: function(id, menu) {
            this.submenu = null;
            this.menu = menu;

            this.childElements().each(function(subs) {
                if (subs.hasClassName && subs.hasClassName('menu')) {
                    this.submenu = subs;
                    return;
                }
            }.bind(this));
            initEvents.call(this);
            this.checked = checked.call(this);
        }
    }
})());

/* Deprecated */
var Menu = IWL.Menu;
var MenuItem = IWL.Menu.Item;
