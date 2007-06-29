// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class Menu is a class for adding menus
 * @extends Widget
 * */
var Menu = {};
Object.extend(Object.extend(Menu, Widget), {
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
		paren_position = Position.cumulativeOffset(this.parentItem);
	    else
		paren_position = Position.positionedOffset(this.parentItem);
	    var paren_dimensions = Element.getDimensions(this.parentItem);
	    if (this.hasClassName('submenu')) {
		Element.setStyle(this, {left: paren_dimensions.width + 'px'});
	    } else {
		Element.setStyle(this, {left: paren_position[0] + 'px',
			top: paren_position[1] + paren_dimensions.height + 'px'});
	    }
	    if (this.options.maxHeight)
		this.__setupScrolling();
	    if (ie4) {
		var dims = this.getDimensions();
		this.setStyle({width: dims.width + 'px', height: dims.height + 'px'});
	    }
	    this.__removeQuirks();
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
	if (this.parentMenu)
	    this.parentMenu.poppedChild = null;
	this.popped = false;
	return this;
    },
    /**
     * If the menu is popped up, it is hidden, else, it is shown
     * @returns The object
     * */
    toggle: function() {
	if (this.popped)
	    this.popDown();
	else
	    this.popUp();
	return this;
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
	element = $(element);
	if (!element) return;
	return element.signalConnect(signal, this._bindPop.bindAsEventListener(this, element));
    },
    /**
     * Selects the given menu item 
     * @param item The menu item to select.
     * @returns The object
     * */
    selectItem: function(item) {
	item = $(item);
	if (!item) return;
	item.setSelected(true);
	return this;
    },
    /**
     * Unelects the given menu item 
     * @param item The menu item to unselect.
     * @returns The object
     * */
    unselectItem: function(item) {
	item = $(item) || this.currentItem;
	if (!item) return;
	item.setSelected(false);
	return this;
    },
    /**
     * Toggles the check or radio menu item
     * @param item The menu item to toggle
     * @returns The object
     * */
    toggleItem: function(item) {
	var item = $(item);
	if (!item) return;
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
		this.menuItems.push(MenuItem.create($_, this));
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
	Event.observe(this, 'mouseover', function() {
	    focused_widget = this.id}.bind(this));
	Event.observe(this, 'click', function() {
	    focused_widget = this.id}.bind(this));
	Event.observe(window, 'click', function(event) {
	    if (!Event.checkElement(event, this))
		this.popDown();
	}.bind(this));
	Event.observe(document.body, 'click', function(event) {
	    if (!Event.checkElement(event, this))
		this.popDown();
	}.bind(this));
//        keyLogEvent(this.__KeyEventsCB.bindAsEventListener(this));
    },
    _bindPop: function(event, parentItem) {
	if (parentItem)
	    this.parentItem = parentItem;
	if (this.popped)
	    this.popDown();
	else
	    this.popUp();
	Event.stop(event);
	return this;
    },
    __removeQuirks: function() {
	if (!ie4 || ie7) return;
	if (this.__qframe) return;
	var dims = Element.getDimensions(this);
	var qframe = Builder.node('iframe', {
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
    },
    __setupScrolling: function() {
	var width = this.getStyle('width');
	var height = this.getStyle('height');
	if (this.options.maxHeight > parseFloat(height)) return;
	var new_width = parseInt(width) + 20;
	this.addClassName('scrolling_menu');
	if (opera)
	    this.setStyle({width: new_width + 'px', height: this.options.maxHeight + 'px', 'overflow': 'auto'});
	else
	    this.setStyle({width: new_width + 'px', height: this.options.maxHeight + 'px', 'overflow-y': 'scroll'});
    },
    __KeyEventsCB: function(event) {
	var keyCode = getKeyCode(event);
	var shift = event.shiftKey;
	if (focused_widget != this.id)
	    return;

	if (keyCode == 37) {		// Left-arrow
	    Event.stop(event);
	} else if (keyCode == 38)  {	// Up-arrow
	    Event.stop(event);
	} else if (keyCode == 39) {	// Right-arrow
	    Event.stop(event);
	} else if (keyCode == 40) {	// Down-arrow
	    Event.stop(event);
	} else if (keyCode == 13) { 	// Enter
	    Event.stop(event);
	}
    }
});

/**
 * @class MenuItem is a class for menu items
 * @extends Widget
 * */
var MenuItem = {};
Object.extend(Object.extend(MenuItem, Widget), {
    /**
     * Sets whether the menu item is selected
     * @param {Boolean} selected True if the item should be selected
     * @returns The object
     * */
    setSelected: function(selected) {
	if (this.isNotEnabled()) return;
	if (selected) {
	    if (this.isSelected()) return;
	    if (this.menu.currentItem)
		this.menu.currentItem.setSelected(false);
	    if (this.menu.hasClassName('menubar'))
		this.addClassName('menubar_item_selected');
	    else
		this.addClassName('menu_item_selected');
	    this.menu.currentItem = this;

	    this.emitSignal('select');
	} else {
	    if (!this.isSelected()) return;
	    if (this.menu.currentItem == this)
		this.menu.currentItem = null;
	    this.removeClassName('menu_item_selected').removeClassName('menubar_item_selected');

	    this.emitSignal('unselect');
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
     * @param {Boolean} selected True if the item should be disabled 
     * @returns The object
     * */
    setDisabled: function(selected) {
	this.removeClassName('menu_item_disabled');
	if (selecte)
	    this.addClassName('menu_item_disabled');
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
	    return this.__toggleCheckItem();
	} else if (this.hasClassName('menu_radio_item')) {
	    return this.__toggleRadioItem();
	}
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
	this.__initEvents();
	this.checked = this.__checked();
    },
    __toggleCheckItem: function() {
	if (!this.hasClassName('menu_check_item')) return;
	if (this.hasClassName('menu_check_item_checked')) {
	    this.checked = false;
	    this.removeClassName('menu_check_item_checked');
	} else {
	    this.checked = true;
	    this.addClassName('menu_check_item_checked');
	}
	this.emitSignal('change');
	return this;
    },
    __toggleRadioItem: function() {
	var paren = this.up();
	
	if (!this.hasClassName('menu_radio_item')) return;
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
	this.emitSignal('change');
	return this;
    },
    __initEvents: function() {
	if (this.menu.hasClassName('menubar')) {
	    if (!this.menu.options.mouseOverActivation) {
		if (this.submenu) {
		    this.observe('click', function(event) {
			if (this.menu.poppedChild && this.menu.poppedChild != this.submenu)
			    this.menu.poppedChild.toggle();
			this.submenu.toggle();
			if (this.submenu.popped)
			    this.setSelected(true);
			else
			    this.setSelected(false);
			Event.stop(event);
		    }.bind(this));
		    this.observe('mouseover', function(event) {
			if (!this.menu.poppedChild || this.menu.poppedChild == this.submenu)
			    return;
			this.menu.poppedChild.toggle();
			this.setSelected(true);
			this.submenu.toggle();
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
        this.observe('mouseover', this.setSelected.bind(this, true));
	if (this.hasClassName('menu_check_item'))
	    this.observe('click', this.__toggleCheckItem.bind(this));
	else if (this.hasClassName('menu_radio_item'))
	    this.observe('click', this.__toggleRadioItem.bind(this));
    },
    __checked: function() {
	if (this.hasClassName('menu_radio_item'))
	    return this.hasClassName('menu_radio_item_checked');
	else if (this.hasClassName('menu_check_item'))
	    return this.hasClassName('menu_check_item_checked');
    }
});
