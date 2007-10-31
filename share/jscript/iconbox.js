// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.Iconbox is a class for creating a container with icons
 * @extends IWL.Widget
 * */
IWL.Iconbox = Object.extend(Object.extend({}, IWL.Widget), (function () {
    function resizeEvent(event) {
        var dims = this.getDimensions();
        if (!this.dimensions || 
                dims.width != this.dimensions.width || 
                dims.height != this.dimensions.height) {
            restoreIconsHeight.call(this);
            if (this._alignDelay && this.loaded) clearTimeout(this._alignDelay);
            this._alignIconsVertically.bind(this).delay(0.1);
        }
    }

    function findIconIdVertical(icon, dir) {
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
    }

    function restoreIconsHeight() {
        if (!this.icons) return;
        this.icons.each(function(icon) {
            if (!icon.default_height)
                return;
            icon.setStyle({height: icon.default_height + 'px'});
        }.bind(this));
    }

    function findMaxHeightOnSameRow(icon) {
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
    }

    function keyEventsCB(event) {
        var keyCode = Event.getKeyCode(event);
        var shift = event.shiftKey;
        var icon;

        if (keyCode == Event.KEY_LEFT) {
            if (icon = this.getPrevIcon()) {
                icon.setSelected(true, shift);
                new Effect.ScrollElement(icon, this.iconsContainer, {duration: 0.3});
                Event.stop(event);
            }
        } else if (keyCode == Event.KEY_RIGHT) {
            if (icon = this.getNextIcon()) {
                icon.setSelected(true, shift);
                new Effect.ScrollElement(icon, this.iconsContainer, {duration: 0.3});
                Event.stop(event);
            }
        } else if (keyCode == Event.KEY_UP)  {
            if (icon = this.getUpperIcon()) {
                icon.setSelected(true, shift);
                new Effect.ScrollElement(icon, this.iconsContainer, {duration: 0.3});
                Event.stop(event);
            }
        } else if (keyCode == Event.KEY_DOWN) {
            if (icon = this.getLowerIcon()) {
                icon.setSelected(true, shift);
                new Effect.ScrollElement(icon, this.iconsContainer, {duration: 0.3});
                Event.stop(event);
            }
        } else if (keyCode == Event.KEY_RETURN) {
            if (this.currentIcon)
                this.currentIcon.activate();
        }
    }

    return {
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
            this.emitSignal('iwl:select_all');
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
            this.emitSignal('iwl:unselect_all');
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
            return findIconIdVertical.call(this, icon, "up");
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
            return findIconIdVertical.call(this, icon, "down");
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

            if (Object.isString(json) || Object.isElement(json))
                json = [json];
            else {
                if (typeof json !== 'object') return;
                if (!json.length) json = [json];
            }
            for (var i = 0; i < json.length; i++) {
                var icon_data = json[i];
                if (!icon_data) continue;
                var icon = null;
                var icon_id = 'iconbox_icon_' + Math.random();
                if (Object.isString(icon_data)) {
                    this.iconsContainer.insert(unescape(icon_data));
                    icon = this.iconsContainer.childElements().last();
                    if (reference)
                        this.iconsContainer.insertBefore(icon, reference);
                } else if (Object.isElement(icon_data)) {
                    if (reference)
                        icon = this.iconsContainer.insertBefore(icon_data, reference);
                    else
                        icon = this.iconsContainer.appendChild(icon_data);
                } else {
                    if (icon_data.src) {
                        icon = new Element('div').update(new Element('img', {id: icon_id + '_image', src: icon_data.src}));
                        if (icon_data.text)
                            icon.appendChild(new Element('p', {id: icon_id + '_label'}).update(icon_data.text));
                        if (reference)
                            this.iconsContainer.insertBefore(icon, reference);
                        else
                            this.iconsContainer.appendChild(icon);
                    } else {
                        icon = this.iconsContainer.createHtmlElement(icon_data, reference);
                    }
                }
                if (!icon.id) icon.id = icon_id;
                icon.addClassName('icon').addClassName($A(this.classNames()).first() + '_icon');
                icon.select('img').first().addClassName('icon_image');
                var label = icon.select('p').first();
                if (label)
                    label.addClassName('icon_label');
                this.icons.push(IWL.Iconbox.Icon.create(icon, this));
            }
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
                this.icons.push(IWL.Iconbox.Icon.create(e, this));
            }.bind(this));

            Event.observe(window, 'resize', 
                    resizeEvent.bindAsEventListener(this));
            this.registerFocus();
            this.keyLogger(keyEventsCB.bindAsEventListener(this));
        },
        _alignIconsVertically: function() {
            if (!this.icons) return;
            this.icons.each(function(icon) {
                if (!icon.default_height)
                    icon.default_height = parseInt(icon.getStyle('height'));
                var height = findMaxHeightOnSameRow.call(this, icon);
                icon.setStyle({height: height + 'px'});
            }.bind(this));
            this.dimensions = this.getDimensions();
            this._alignDelay = false;
        },
        _refreshResponse: function(json, params, options) {
            if (!json.icons.length) return;
            if (this.currentIcon) this.currentIcon.setSelected(false);
            this.iconsContainer.update();
            this.icons = [];
            this._iconCount = json.icons.length;
            return this.appendIcon(json.icons);
        },
        _iconCountdown: function() {
            if (--this._iconCount <= 0) {
                if (this._alignDelay) clearTimeout(this._alignDelay);
                (function() {
                    this._alignIconsVertically();
                    if (!this.loaded) this.emitSignal.bind(this, 'iwl:load').delay(0.15);
                    this.loaded = true;
                }).bind(this).delay(0.1);
                this._iconCount = 0;
            }
        }
    }
})());

/**
 * @class IWL.Iconbox.Icon is a class for iconbox icons
 * @extends IWL.Widget
 * */
IWL.Iconbox.Icon = Object.extend(Object.extend({}, IWL.Widget), (function () {
    function initEvents() {
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

    return {
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
                this.emitSignal('iwl:select');
                this.iconbox.statusbarPush(this.getLabel());
            } else {
                if (!this.isSelected()) return;
                this.removeClassName("icon_selected");
                if (this.iconbox.currentIcon == this)
                    this.iconbox.currentIcon = null;
                if (this.iconbox.options.multipleSelect)
                    this.iconbox.selectedIcons = this.iconbox.selectedIcons.without(this);
                this.emitSignal('iwl:unselect');
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
         * Activates the icon
         * @returns The object
         * */
        activate: function() {
            this.emitSignal('iwl:activate');
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
            var message = unescape(this.iconbox.messages['delete']).replace(/{TITLE}/, title);
            this.iconbox.statusbarPush(message);
            if (this.iconbox._alignDelay && this.iconbox.loaded)
                clearTimeout(this.iconbox._alignDelay);
            this.iconbox._alignIconsVertically.bind(this).delay(0.1);
            this.emitSignal('iwl:remove');
            return this;
        },

        _init: function(id, iconbox) {
            this.iconbox = iconbox;
            this.label = this.select('.icon_label')[0];
            this.image = this.select('img')[0];
            initEvents.call(this);
            if (this.image.complete)
                this.iconbox._iconCountdown();
            else
                this.image.observe('load', this.iconbox._iconCountdown.bind(this.iconbox));
        }
    }
})());

/* Deprecated */
var Iconbox = IWL.Iconbox;
var Icon = IWL.Iconbox.Icon;
