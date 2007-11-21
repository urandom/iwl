// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.Contentbox is a class for adding window-like containers
 * @extends IWL.Widget
 * */
IWL.Contentbox = Object.extend(Object.extend({}, IWL.Widget), (function () {
    function createButtonsElement() {
        if (this.buttons) return;
        var element = new Element('div', {
            "class": $A(this.classNames()).first() + '_buttons', "id": this.id + '_buttons'});
        this.contentboxTitle.appendChild(element);
        this.buttons = element;
    }

    function createCloseElement() {
        if (this.closeButton) return;
        if (!this.buttons) createButtonsElement.call(this);
        var element = new Element('div', {
            "class": $A(this.classNames()).first() + '_close', "id": this.id + '_close'});
        this.buttons.appendChild(element);
        this.closeButton = element;
        this.closeButton.signalConnect('click', this.close.bindAsEventListener(this));
        if (this.resizeButton) {
            this.resizeButton.remove();
            this.buttons.appendChild(this.resizeButton);
        }
    }

    function createResizeElement() {
        if (this.resizeButton) return;
        if (!this.buttons) createButtonsElement.call(this);
        var element = new Element('div', {
            "class": $A(this.classNames()).first() + '_resize', "id": this.id + '_resize'});
        this.buttons.appendChild(element);
        this.resizeButton = element;
    }

    function calculateWidth(element) {
        element = $(element);
        if (!element) return 0;
        var delta = horizontalPadding.call(this);
        var d;
        element.cleanWhitespace();
        if (element.childNodes.length == 1) {
            if (element.firstChild.tagName)
                d = $(element.firstChild).getDimensions().width + delta;
        } else {
            var max = 0;
            var cumulative = 0;
            for (var i = 0; i < element.childNodes.length; i++) {
                var child = Element.extend(element.childNodes[i]);
                var width = child.getDimensions().width;
                if (child.getStyle('position') == 'absolute') continue;
                if (child.tagName != 'BR' && (
                        child.getStyle('display') == 'inline' ||
                        child.getStyle('float') != 'none')
                ) {
                    cumulative += width;
                    max = max > cumulative ? max : cumulative;
                } else {
                    cumulative = 0;
                    max = max > width ? max : width;
                }
            }
            d = max + delta;
        }
        return d;
    }

    function setupDrag() {
        this.contentboxTitle.style.cursor = 'move';
        this.contentboxTitle.parentNode.style.cursor = 'move';
        this._draggable = new Draggable(this, {
            handle:      $(this.id + '_title'),
            starteffect: null,
            endeffect:   endDragCallback.bind(this)});
        setFocus.call(this);
        return this.observe('click', setFocus.bind(this));
    }

    function setupClose() {
        createCloseElement.call(this);
        return this;
    }

    function setupResize() {
        createResizeElement.call(this);
        this._resizer = new Resizer(this, {
            maxHeight: 1000,
            maxWidth: 1000,
            minHeight: 70,
            minWidth: 70,
            outline: this.options.typeOptions.outline,
            onResize: resizeCallback.bind(this),
            togglers: [this.resizeButton]
        });

        return this;
    }

    function setupModal() {
        if (this.modalElement) return;
        if (!this.originalPosition)
            this.originalPosition = this.getStyle('position');
        if (this.originalPosition != 'absolute')
            this.absolutize();
        var paren = this.parentNode;
        var zIndex = parseInt(this.getStyle('z-index'));
        this.modalElement = new Element('div', {
            id: this.id + '_modal', className: 'modal_view'
        });
        paren.insertBefore(this.modalElement, this);
        if (this.options.closeModalOnClick)
            this.modalElement.observe('click', this.close.bind(this));
        this.modalElement.setOpacity(this.options.modalOpacity);
        this.modalElement.setStyle({zIndex: zIndex - 1});
        var page_dims = document.viewport.getMaxDimensions();
        this.modalElement.setStyle({
            height: page_dims.height + 'px',
            width: page_dims.width + 'px'
        });
        Event.observe(window, 'resize', function() {
            if (!this.modalElement) return;
            var page_dims = document.viewport.getMaxDimensions();
            this.modalElement.setStyle({
                height: page_dims.height + 'px',
                width: page_dims.width + 'px'
            });
        }.bind(this));
        if (Prototype.Browser.IE && !Prototype.Browser.IE7) {
            if (this.options.modal) {
                this.__qframe = new Element('iframe', {
                    src: "javascript: false", className: "qframe",
                    style: "width: " + page_dims.width + "px; height: " + page_dims.height + "px;"
                });
                this.__qframe.setStyle({top: '0px', left: '0px', position: 'absolute'});
                paren.insertBefore(this.__qframe, this.modalElement);
            }
        }
    }

    function disableModal() {
        if (!this.modalElement) return;
        this.modalElement.parentNode.removeChild(this.modalElement);
        this.modalElement = null;
        if (this.__qframe) {
            this.__qframe.parentNode.removeChild(this.__qframe);
            this.__qframe = null;
        }
        if (this.originalPosition != 'absolute') {
            this.relativize();
            this.style.position = this.originalPosition;
        }
    }

    function horizontalPadding() {
        var paren = this.contentboxContent.up();
        var pl = parseInt(this.contentboxContent.getStyle('padding-left')) 
            + parseInt(paren.getStyle('padding-left')) 
            + parseInt(paren.up().getStyle('padding-left'));
        var pr = parseInt(this.contentboxContent.getStyle('padding-right')) 
            + parseInt(paren.getStyle('padding-right'))
            + parseInt(paren.up().getStyle('padding-right'));
        if (arguments[0] && arguments[0] == 'left')
            return pl;
        else if (arguments[0] && arguments[0] == 'right')
            return pr;
        else
            return pl + pr;
    }

    function removeQuirks() {
        return;
        if (!Prototype.Browser.IE || Prototype.Browser.IE7) return;
        if (this.options.modal) return;
        if (this.__qframe) return;
        var dims = this.getDimensions();
        var qframe = new Element('iframe', {
            src: "javascript: false", className: "qframe",
            top: "0px", left: "0px",
            style: "width: " + dims.width + "px; height: " + dims.height + "px;"
        });
        this.__qframe = $(qframe);
        this.insertBefore(qframe, this.firstChild);
    }

    function resizeCallback(element, event, d) {
        var middle;
        var height = 0;
        var resizerName = this._resizer ? this._resizer.options.className : '';
        var className =$A(this.classNames()).first(); 
        this.childElements().each(function($_) {
            if ($_.hasClassName(className + '_middle')) {
                middle = $_;
                return;
            }

            var ok = false;
            ['top', 'title', 'header', 'footer', 'bottom'].each(function(c) {
                if ($_.hasClassName(className + '_' + c)) {
                    ok = true;
                    throw $break;
                }
            }.bind(this));
            if (!ok) return;
            height += $_.getHeight();
        }.bind(this));
        middle.style.height = (d.h - height) + 'px';
    }

    function hideQuirks() {
        if (!Prototype.Browser.IE || Prototype.Browser.IE7) return;
        if (this.options.modal) return;
        var problematic = ["applet", "select", "iframe"];
        var dim = this.getDimensions();
        var pos = this.cumulativeOffset();
        var thisDelta = {x1: pos[0], x2: pos[0] + dim.width, y1: pos[1], y2: pos[1] + dim.height};
        for (var k = 0; k < problematic.length; k++) {
            var pr_el = $A(document.getElementsByTagName(problematic[k]));
            pr_el.each(function(el, $i) {
                el = $(el);
                if (el.descendantOf(this)) return;
                var pos = el.cumulativeOffset();
                var dim = el.getDimensions();
                var delta = {x1: pos[0], x2: pos[0] + dim.width, y1: pos[1], y2: pos[1] + dim.height};
                if (!el._originalVisibility)
                    el._originalVisibility = el.getStyle('visibility');
                if ((delta.x1 > thisDelta.x2) || (delta.x2 < thisDelta.x1) || (delta.y1 > thisDelta.y2) || (delta.y2 < thisDelta.y1)) {
                    el.style.visibility = el._originalVisibility;
                } else {
                    el.style.visibility = 'hidden';
                }
                if (this.hiddenQuirks.indexOf(el) == -1)
                    this.hiddenQuirks.push(el);
            }.bind(this));
        }
    }

    function endDragCallback() {
        setFocus.call(this);
        hideQuirks.call(this);
    }

    function setFocus() {
        var zIndex = parseInt(this.getStyle('z-index'));
        var prevsel = window.selectedContentbox;
        if (prevsel) {
            if (prevsel == this)
                return;
            zIndex = parseInt(prevsel.getStyle('z-index')) - 1;
            prevsel.className = 
                prevsel.className.replace(/ contentbox_selected/, '');
            prevsel.setStyle({zIndex: zIndex});
            if (prevsel.modalElement)
                prevsel.modalElement.setStyle({zIndex: zIndex - 1});
        }
        this.addClassName('contentbox_selected');
        window.selectedContentbox = this;
        if (this.modalElement)
            this.modalElement.setStyle({zIndex: zIndex});
        return this.setStyle({zIndex: zIndex + 1});
    }

    return {
        /**
         * Shows the contentbox
         * @returns The object
         * */
        show: function() {
            if (!this.parentNode)
                ($(arguments[0]) || document.body).appendChild(this);
            else
                this.style.display = '';
            if (this.options.modal) setupModal.call(this);
            return this.emitSignal('iwl:show');
        },
        /**
         * Hides the contentbox
         * @returns The object
         * */
        hide: function() {
            this.style.display = 'none';
            return this.emitSignal('iwl:hide');
        },
        /**
         * Closes the contentbox
         * @returns The object
         * */
        close: function() {
            if (!this.parentNode) return;
            if (this.options.modal) disableModal.call(this);
            this.parentNode.removeChild(this);
            $A(this.hiddenQuirks).each(function(el) {
                el.style.visibility = el._originalVisibility;
            });
            return this.emitSignal('iwl:close');
        },
        /**
         * Sets the type of the contentbox
         * @param {String} type The type of the contentbox. The following values are recognised:
         * 		drag - enables dragging
         * 		resize - enables resizing
         * 		dialog - enables dragging and resizing
         * 		window - enables dragging, resizing and closing
         * 		noresize - enables dragging and closing
         * 		none - disables everything
         * @param {Object} options Options for the selected type
         *          outline - turns on outline moving/resizing
         * @returns The object
         * */
        setType: function(type, options) {
            this.options.type = type;
            this.options.typeOptions =
                Object.extend(this.options.typeOptions, options || {});

            if (type == 'drag')
                this.setDrag();
            else if (type == 'resize')
                this.setResize();
            else if (type == 'dialog')
                this.setDialog();
            else if (type == 'window')
                this.setWindow();
            else if (type == 'noresize')
                this.setNoResize();
            else if (type == 'none')
                this.setNoType();

            return this;
        },
        /**
         * Enables dragging of the contentbox
         * @returns The object
         * */
        setDrag: function() {
            this.setNoType();
            return setupDrag.call(this);
        },
        /**
         * Enables resizing of the contentbox
         * @returns The object
         * */
        setResize: function() {
            this.setNoType();
            return setupResize.call(this);
        },
        /**
         * Enables closing of the contentbox
         * @returns The object
         * */
        setClose: function() {
            this.setNoType();
            return setupClose.call(this);
        },
        /**
         * Enables dragging and resizing of the contentbox
         * @returns The object
         * */
        setDialog: function() {
            this.setNoType();
            setupResize.call(this);
            return setupDrag.call(this);
        },
        /**
         * Enables dragging, resizing and closing of the contentbox
         * @returns The object
         * */
        setWindow: function() {
            this.setNoType();
            setupClose.call(this);
            setupResize.call(this);
            return setupDrag.call(this);
        },
        /**
         * Enables dragging and closing of the contentbox
         * @returns The object
         * */
        setNoResize: function() {
            this.setNoType();
            setupClose.call(this);
            return setupDrag.call(this);
        },
        /**
         * Disables the dynamic features of contentbox
         * @returns The object
         * */
        setNoType: function() {
            this.contentboxTitle.style.cursor = 'default';
            this.contentboxTitle.parentNode.style.cursor = 'default';
            if (this.closeButton) {
                this.closeButton.remove();
                this.closeButton = null;
            }
            if (this.resizeButton) {
                this.resizeButton.remove();
                this.resizeButton = null;
            }
            if (this._draggable)
                this._draggable.destroy();
            if (this.contentbox_resize) {
                this.contentbox_resize.parentNode.removeChild(this.contentbox_resize);
                this.contentbox_resize = null;
            }
            if (this._resizer)
                this._resizer.destroy();
            return this;
        },
        /**
         * Sets whether the contentbox is a modal one
         * @param {Boolean} modal True if the contentbox is a modal one
         * @returns The object
         * */
        setModal: function(modal) {
            this.options.modal = !!modal;
            if (this.options.modal)
                setupModal.call(this);
            else
                disableModal.call(this);
            return this;
        },
        /**
         * Sets whether the contentbox should have shadows
         * @param {Boolean} shadows True if the contentbox should have shadows
         * @returns The object
         * */
        setShadows: function(shadows) {
            if (this.options.hasShadows == shadows) return;
            this.options.hasShadows = shadows;
            this.removeClassName('shadowbox');
            if (shadows)
                this.addClassName('shadowbox');
            return this;
        },
        /**
         * Calculates the content of the contentbox, and adjusts the width to fit it
         * @return The object
         * */
        autoWidth: function() {
            var d = {};
            var tw = calculateWidth.call(this, this.contentboxTitle);
            var hw = calculateWidth.call(this, this.contentboxHeader);
            var cw = calculateWidth.call(this, this.contentboxContent);
            var fw = calculateWidth.call(this, this.contentboxFooter);
            d.width = Math.max(tw, hw, cw, fw) + 'px';
            if (d.width)
                this.setStyle(d);
            if (this.options.positionAtCenter)
                this.positionAtCenter();
            return this;
        },
        /**
         * Sets the title of the contentbox
         * @param element The title can be a DOM element, or a string
         * @returns The object
         * */
        setTitle: function(element) {
            var label = $(this.id + '_title_label');
            if (!label)
                label = this.contentboxTitle.appendChild(new Element('span', {id: this.id + '_title_label', className: $A(this.classNames()).first() + '_title_label'}));
            label.update(element);
            return this;
        },
        /**
         * Returns the text of the contentbox title
         * @returns The title
         * @type Text
         * */
        getTitle: function() {
            var label = $(this.id + '_title_label');
            if (!label) return '';
            return label.getText();
        },
        /**
         * Returns the elements that make up the title of the contentbox
         * @returns The title elements
         * @type Array
         * */
        getTitleElements: function() {
            var label = $(this.id + '_title_label');
            if (!label) return [];
            return $A(label.cleanWhitespace().childNodes);
        },
        flush: function() {
            var w = this.getDimensions().width;
            this.setStyle({width: w + 1 + 'px'});
            this.setStyle.bind(this, {width: w + 'px'}).defer();
        },

        _preInit: function() {
            if (!this.current) {
                var args = arguments;
                setTimeout(function() {
                    this.create.apply(this, args)
                }.bind(this), 200);
                return false;
            }
            return true;
        },
        _init: function(id) {
            this.options = Object.extend({
                type: 'none',
                typeOptions: {},
                modal: false,
                hasShadows: false,
                autoWidth: false,
                closeModalOnClick: false,
                positionAtCenter: false,
                modalOpacity: 0.7
            }, arguments[1] || {});
            this.contentboxTitle = $(id + '_titler');
            this.contentboxHeader = $(id + '_header');
            this.contentboxContent = $(id + '_content');
            this.contentboxFooter = $(id + '_footerr');
            this.modalElement = null;
            this.hiddenQuirks = [];

            var original_visibility = this.getStyle('visibility');
            this.setStyle({visibility: 'hidden'});
            var deter_visibility = false;

            this.setType(this.options.type);

            if (this.options.autoWidth) {
                var deter_visibility = true;
                setTimeout(function() {
                    this.autoWidth();
                    removeQuirks.call(this);
                    this.setStyle({visibility: original_visibility});
                }.bind(this), 250);
            } else {
                removeQuirks.call(this);
                if (this.options.positionAtCenter)
                    this.positionAtCenter();
            }
            if (this.options.modal)
                this.setModal(true);
            if (!deter_visibility)
                this.setStyle({visibility: original_visibility});
        }
    }
})());

/* Deprecated */
var Contentbox = IWL.Contentbox;
