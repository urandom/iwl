// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class Iconbox is a class for creating a container with icons
 * @extends Widget
 * */
var Iconbox = {};
Object.extend(Object.extend(Iconbox, Widget), {
    /**
     * Selects the given icon 
     * @param icon The icon to select. If none is given, the current one is used.
     * @returns The object
     * */
    selectIcon: function(icon) {
	var icon = $(icon);
	if (!icon) return;
	icon.setSelected(true);
	return this;
    },
    /**
     * Unselects the given icon 
     * @param icon The icon to unselect. If none is given, the current one is used.
     * @returns The object
     * */
    unselectIcon: function(icon) {
	var icon = $(icon) || this.currentIcon;
	if (!icon) return;
	icon.setSelected(false);
	return this;
    },
    /**
     * Selects all the icons
     * @returns The object
     * */
    selectAllIcons: function() {
	this.selectedIcons = [];
	if (!this.options.multipleSelect) return;
	this.icons.each(function(icon) {
	    icon.addClassName('icon_selected');
	    this.selectedIcons.push(icon);
	}.bind(this));
	this.currentIcon = this.selectedIcons[this.selectedIcons.length - 1];
	this.emitSignal('select_all');
	return this;
    },
    /**
     * Unselects all the icons
     * @returns The object
     * */
    unselectAllIcons: function() {
	this.selectedIcons.each(function(icon) {
	    icon.removeClassName("icon_selected");
	});
	this.selectedIcons = [];
	this.emitSignal('unselect_all');
	return this;
    },
    /**
     * @returns The currently selected icon
     * */
    getSelectedIcon: function() {
	return this.currentIcon;
    },
    /**
     * @returns An array of all the selected icons
     * */
    getSelectedIcons: function() {
	return this.selectedIcons;
    },
    /**
     * Returns the previous icon
     * @param icon The reference icon. If none is given, the current one is used.
     * @returns The previous icon
     * */
    getPrevIcon: function() {
	var icon = $(arguments[0]) || this.currentIcon;
	if (!icon)
	    return this.icons[0];
	return this.icons[this.icons.indexOf(icon) - 1];
    },
    /**
     * Returns the next icon
     * @param icon The reference icon. If none is given, the current one is used.
     * @returns The next icon
     * */
    getNextIcon: function() {
	var icon = $(arguments[0]) || this.currentIcon;
	if (!icon)
	    return this.icons[0];
	return this.icons[this.icons.indexOf(icon) + 1];
    },
    /**
     * Returns the upper icon
     * @param icon The reference icon. If none is given, the current one is used.
     * @returns The upper icon
     * */
    getUpperIcon: function() {
	var icon = $(arguments[0]) || this.currentIcon;
	if (!icon)
	    return this.icons[0];
	return this._findIconIdVertical(icon, "up");
    },
    /**
     * Returns the lower icon
     * @param icon The reference icon. If none is given, the current one is used.
     * @returns The lower icon
     * */
    getLowerIcon: function() {
	var icon = $(arguments[0]) || this.currentIcon;
	if (!icon)
	    return this.icons[0];
	return this._findIconIdVertical(icon, "down");
    },
    /**
     * Removes the given icon
     * @param icon The icon to remove. If none is given, the current one is used.
     * @returns The object
     * */
    removeIcon: function(icon) {
	var icon = $(icon) || this.currentIcon;
	if (!icon) return;
	icon.remove();
	return this;
    },
    /**
     * Appends an icon, or an array of icons
     * @param json The icon json object or HTML string to append. It can be an array of such objects
     * @param reference A reference icon. If given, the created icon will be inserted before this one
     * @returns The object
     * */
    appendIcon: function(json) {
	var reference = $(arguments[1]);
	if (!json) return;

	if (typeof json === 'string')
	    json = [json];
	else {
	    if (typeof json !== 'object') return;
	    if (!json.length)
		json = [json];
	}
	for (var i = 0; i < json.length; i++) {
	    var icon_data = json[i];
	    if (!icon_data) continue;
            var icon = null;
	    if (typeof icon_data === 'string') {
		new Insertion.Bottom(this.iconsContainer, decodeURIComponent(icon_data));
		icon = this.iconsContainer.childElements().last();
		if (!icon.id)
		    icon.id = 'iconbox_icon_' + Math.random();
		if (reference)
		    this.iconsContainer.insertBefore(icon, reference);
	    } else {
		icon = createHtmlElement(icon_data, this.iconsContainer, reference);
            }
	    this.icons.push(Icon.create(icon, this));
	}
	this._alignIconsVertically();
	return this;
    },

    /**
     * Sets the status bar text
     * @param {String} text The text to be shown in the status bar
     * @returns The object
     * */
    statusbarPush: function(text) {
	if (!this.statusbar) return;
	this.statusbar.update(text);
	return this;
    },

    _init: function(id) {
	this.statusbar = $(id + '_status_label');
	this.iconsContainer = this.down();
	this.icons = new Array;
	this.selectedIcons = new Array;
	this.currentIcon = null;
	this.options = Object.extend({
	    multipleSelect: false,
	    clickToSelect: true
	}, arguments[1] || {});
	this.messages = Object.extend({}, arguments[2]);

	var childElements = [];
	this.iconsContainer.childElements().each(function(e) {
	    if (e.hasClassName('icon'))
		childElements.push(e);
	});
	this._iconCount = childElements.length;
	childElements.each(function(e) {
	    this.icons.push(Icon.create(e, this));
	}.bind(this));

	Event.observe(window, 'resize', 
		this._resizeEvent.bindAsEventListener(this));
	Event.observe(this, 'mouseover', function() {
	    focused_widget = this.id}.bind(this));
	Event.observe(this, 'click', function() {
	    focused_widget = this.id}.bind(this));
	keyLogEvent(this.__keyEventsCB.bindAsEventListener(this));
    },
    _resizeEvent: function(event) {
	var dims = Element.getDimensions(this);
	if (!this.dimensions || 
		dims.width != this.dimensions.width || 
		dims.height != this.dimensions.height) {
	    this._restoreIconsHeight();
	    this._alignIconsVertically();
	}
    },

    /* assumes variable height PER row */
    _findIconIdVertical: function(icon, dir) {
	var offsetLeftlb;
	var offsetLeftub;
	var offsetTop = icon.offsetTop;
	var offsetLeft = icon.offsetLeft;
	var dims = Element.getDimensions(icon);
	var width = dims.width;

	offsetLeftlb = offsetLeft - width/2;
	offsetLeftub = offsetLeft + width/2;
        var prevtop = 0;
        this.icons.each(function(iter) {
            var cur_top = iter.offsetTop;
            if (dir == 'up') {
                if (cur_top < offsetTop && prevtop < cur_top)
                    prevtop = cur_top;
            } else {
                if (cur_top > offsetTop && (!prevtop || prevtop > cur_top))
                    prevtop = cur_top;
            }
        }.bind(this));
	for (var i = 0; i < this.icons.length; i++) {
	    var testicon = this.icons[i];
	    if (prevtop && testicon.offsetTop == prevtop) {
		if (testicon.offsetLeft > offsetLeftlb
			&& testicon.offsetLeft < offsetLeftub) {
		    var newicon = testicon;
		    return newicon;
		}
	    }
	}
    },
    _restoreIconsHeight: function() {
        if (!this.icons) return;
        this.icons.each(function(icon) {
	    if (!icon.default_height)
		return;
            icon.setStyle({height: icon.default_height + 'px'});
        }.bind(this));
    },
    _alignIconsVertically: function() {
        if (!this.icons) return;
        this.icons.each(function(icon) {
	    if (!icon.default_height)
		icon.default_height = parseInt(icon.getStyle('height'));
            var height = this._findMaxHeightOnSameRow(icon);
            icon.setStyle({height: height + 'px'});
        }.bind(this));
	this.dimensions = this.getDimensions();
    },
    _findMaxHeightOnSameRow: function(icon) {
        var offset_top = icon.offsetTop;
        var height = parseInt(icon.getStyle('height'));
        for (var i = 0; i < this.icons.length; i++) {
            var testicon = this.icons[i];
            if (icon == testicon) continue;
            if (testicon.offsetTop == offset_top) {
                var testheight = parseInt(testicon.getStyle('height'));
                if (testheight > height)
                    height = testheight;
            }
        }
        return height;
    },
    _refreshResponse: function(json, params) {
	if (!json.icons.length) return;
	if (this.currentIcon) this.currentIcon.setSelected(false);
	this.iconsContainer.update();
	this.icons = [];
	this._iconCount = json.icons.length;
	return this.appendIcon(json.icons);
    },
    _iconCountdown: function() {
	this._iconCount--;

	if (this._iconCount == 0) {
	    this._alignIconsVertically();
	    setTimeout(this.emitSignal.bind(this, 'load'), 100);
	}
    },

    __keyEventsCB: function(event) {
	var keyCode = getKeyCode(event);
	var shift = event.shiftKey;
	var icon;
	if (focused_widget != this.id)
	    return;

	if (keyCode == 37) {		// Left-arrow
	    if (icon = this.getPrevIcon())
		icon.setSelected(true, shift);
	    Event.stop(event);
	} else if (keyCode == 38)  {	// Up-arrow
	    if (icon = this.getUpperIcon())
		icon.setSelected(true, shift);
	    Event.stop(event);
	} else if (keyCode == 39) {	// Right-arrow
	    if (icon = this.getNextIcon())
		icon.setSelected(true, shift);
	    Event.stop(event);
	} else if (keyCode == 40) {	// Down-arrow
	    if (icon = this.getLowerIcon())
		icon.setSelected(true, shift);
	    Event.stop(event);
	} else if (keyCode == 13) { 	// Enter
	    if (this.currentIcon)
		this.currentIcon.activate();
	}
    }
});

/**
 * @class Icon is a class for iconbox icons
 * @extends Widget
 * */
var Icon = {};
Object.extend(Object.extend(Icon, Widget), {
    /**
     * Sets whether the icon is selected
     * @param {Boolean} selected True if the icon should be selected
     * @returns The object
     * */
    setSelected: function(selected, shift) {
	if (selected) {
	    if (this.isSelected()) return;
	    if (this.iconbox.options.multipleSelect) {
		if (!shift) this.iconbox.unselectAllIcons();
	    } else {
		if (this.iconbox.currentIcon)
		    this.iconbox.currentIcon.setSelected(false);;
	    }
	    this.addClassName("icon_selected");
	    this.iconbox.currentIcon = this;
	    if (this.iconbox.scrollToSelection)
		this.scrollTo();

	    if (this.iconbox.options.multipleSelect)
		this.iconbox.selectedIcons.push(this);
	    this.emitSignal('select');
	    this.iconbox.statusbarPush(this.getLabel());
	} else {
	    if (!this.isSelected()) return;
	    this.removeClassName("icon_selected");
	    if (this.iconbox.currentIcon == this)
		this.iconbox.currentIcon = null;
	    if (this.iconbox.options.multipleSelect)
		this.iconbox.selectedIcons = this.iconbox.selectedIcons.without(this);
	    this.emitSignal('unselect');
	}
	return this;
    },
    /**
     * @returns True if the icon is selected
     * @type Boolean
     * */
    isSelected: function() {
	return this.hasClassName('icon_selected');
    },
    /**
     * @returns The icon label
     * @type String
     * */
    getLabel: function() {
	if (!this.label) return '';
	return this.label.getText();
    },
    /**
     * Activated the icon
     * @returns The object
     * */
    activate: function() {
	this.emitSignal('activate');
	return this;
    },
    /**
     * @returns The previous icon
     * */
    prevIcon: function() {
	return this.iconbox.getPrevIcon(this);
    },
    /**
     * @returns The next icon
     * */
    nextIcon: function() {
	return this.iconbox.getNextIcon(this);
    },
    /**
     * @returns The upper icon
     * */
    upperIcon: function() {
	return this.iconbox.getUpperIcon(this);
    },
    /**
     * @returns The lower icon
     * */
    lowerIcon: function() {
	return this.iconbox.getLowerIcon(this);
    },
    /**
     * Removes the icon
     * @returns The object
     * */
    remove: function() {
	var dom_parent = this.parentNode;
	var title = this.getLabel();
	var prev = this.prevIcon() || this.nextIcon();

	this.setSelected(false);
	if (prev) prev.setSelected(true);
	dom_parent.removeChild(this);
	this.iconbox.icons = this.iconbox.icons.without(this);
	var message = this.iconbox.messages['delete'].replace(/{TITLE}/, "'" + title + "'");
	this.iconbox.statusbarPush(message);
	this.iconbox._alignIconsVertically();
	this.emitSignal('remove');
	return this;
    },

    _init: function(id, iconbox) {
	this.iconbox = iconbox;
	this.label = this.getElementsByClassName('icon_label')[0];
	this.__initEvents();
	if (this._loaded)
	    this.iconbox._iconCountdown();
    },
    __initEvents: function() {
	Event.observe(this, "mouseover", function(event) {
	    if (!this.iconbox.options.clickToSelect 
		&& !this.iconbox.options.multipleSelect)
		this.setSelected(true);
	}.bind(this));
	Event.observe(this, "click", function(event) {
	    if (!this.iconbox.options.clickToSelect
		&& !this.iconbox.options.multipleSelect)
		this.activate();
	    else {
		if (event.ctrlKey) {
		    if (this.isSelected())
			this.setSelected(false, true);
		    else
			this.setSelected(true, true);
		} else {
		    this.iconbox.unselectAllIcons();
		    this.setSelected(true);
		    this.iconbox.selectedIcons = [this];
		}
	    }
	}.bind(this));
	Event.observe(this, "dblclick", function(event) {
	    this.activate();
	}.bind(this));
    }
});
