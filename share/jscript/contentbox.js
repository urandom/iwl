// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class Contentbox is a class for adding window-like containers
 * @extends Widget
 * */
var Contentbox = {};
Object.extend(Object.extend(Contentbox, Widget), {
    /**
     * Shows the contentbox
     * @returns The object
     * */
    show: function() {
	var paren = arguments[0] || document.body;
	paren.appendChild(this);
	if (this.options.modal) this.__setupModal();
	return this;
    },
    /**
     * Closes the contentbox
     * @returns The object
     * */
    close: function() {
	if (!this.parentNode) return;
	if (this.options.modal) this.__disableModal();
        this.parentNode.removeChild(this);
	$A(this.hiddenQuirks).each(function(el) {
	    el.style.visibility = el._originalVisibility;
	});
	return this.emitSignal('close');
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
     * @returns The object
     * */
    setType: function(type) {
	this.options.type = type;

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
	return this.__setupDrag();
    },
    /**
     * Enables resizing of the contentbox
     * @returns The object
     * */
    setResize: function() {
	this.setNoType();
	return this.__setupResize();
    },
    /**
     * Enables closing of the contentbox
     * @returns The object
     * */
    setClose: function() {
	this.setNoType();
	return this.__setupClose();
    },
    /**
     * Enables dragging and resizing of the contentbox
     * @returns The object
     * */
    setDialog: function() {
	this.setNoType();
	this.__setupDrag();
	return this.__setupResize();
    },
    /**
     * Enables dragging, resizing and closing of the contentbox
     * @returns The object
     * */
    setWindow: function() {
	this.setNoType();
	this.__setupClose();
	this.__setupDrag();
	return this.__setupResize();
    },
    /**
     * Enables dragging and closing of the contentbox
     * @returns The object
     * */
    setNoResize: function() {
	this.setNoType();
	this.__setupClose();
	return this.__setupDrag();
    },
    /**
     * Disables the dynamic features of contentbox
     * @returns The object
     * */
    setNoType: function() {
	this.contentboxTitle.style.cursor = 'default';
	this.contentboxTitle.parentNode.style.cursor = 'default';
	if (this.contentbox_close) {
	    this.contentbox_close.parentNode.removeChild(this.contentbox_close);
	    this.contentbox_close = null;
	}
	if (this._draggable)
	    this._draggable.destroy();
	if (this.contentbox_resize) {
	    this.contentbox_resize.parentNode.removeChild(this.contentbox_resize);
	    this.contentbox_resize = null;
	}
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
	    this.__setupModal();
	else
	    this.__disableModal();
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
	var tw = this.__checkTitleWidth();
	var hw = this.__checkHeaderWidth();
	var cw = this.__checkContentWidth();
	var fw = this.__checkFooterWidth();
	d.width = Math.max(tw, hw, cw, fw) + 'px';
        if (d.width)
            this.setStyle(d);
	return this;
    },
    /**
     * Focuses the contentbox
     * @returns The object
     * */
    setFocus: function() {
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
    },
    /**
     * Sets the title of the contentbox
     * @param element The title can be a DOM element, or a string
     * @returns The object
     * */
    setTitle: function(element) {
	var text = false;
	if (typeof element == 'string') {
	    element = element.createTextNode();
	    text = true;
	}
	element = $(element);
	if (!element) return;
	if (text) {
	    var label = $(this.id + '_title_label');
	    if (!label)
		label = this.contentboxTitle.appendChild(Builder.node('span', {id: this.id + '_title_label', className: $A(this.classNames()).first() + '_title_label'}));
	    label.update();
	    label.appendChild(element);
	} else {
	    this.contentboxTitle.update();
	    this.contentboxTitle.appendChild(element);
	}
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
	return $A(this.contentboxTitle.childNodes);
    },
    flush: function() {
        var w = this.getDimensions().width;
        this.setStyle({width: w + 1 + 'px'});
        setTimeout(function() {
                this.setStyle({width: w + 'px'});
        }.bind(this), 10);
    },

    _pre_init: function() {
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
	    auto: false,
	    type: 'none',
	    modal: false,
	    hasShadows: false,
	    closeModalOnClick: false,
	    modalOpacity: 0.7
	}, arguments[1] || {});
	this.contentboxTitle = $(id + '_titler');
	this.contentboxHeader = $(id + '_header');
	this.contentboxContent = $(id + '_content');
	this.contentboxFooter = $(id + '_footerr');
	this.pointerPosition = false;
	this.modalElement = null;
	this.hiddenQuirks = [];

	var original_visibility = this.getStyle('visibility');
	this.setStyle({visibility: 'hidden'});
	var deter_visibility = false;

	this.setType(this.options.type);

	if (this.options.auto) {
	    var deter_visibility = true;
	    setTimeout(function() {
		this.autoWidth();
		this.__removeQuirks();
		this.setStyle({visibility: original_visibility});
	    }.bind(this), 250);
	} else
	    this.__removeQuirks();
	if (this.options.modal)
	    this.setModal(true);
	if (!deter_visibility)
	    this.setStyle({visibility: original_visibility});
    },

    __disableModal: function() {
	if (!this.modalElement) return;
	this.modalElement.parentNode.removeChild(this.modalElement);
	this.modalElement = null;
	if (this.__qframe) {
	    this.__qframe.parentNode.removeChild(this.__qframe);
	    this.__qframe = null;
	}
    },
    __createResizeElement: function() {
	if (this.contentbox_resize) return;
	var element = Builder.node('div', {
	    "class":$A(this.classNames()).first() + '_resize', "id":this.id + '_resize'});
	if (this.contentboxFooter)
	    this.contentboxFooter.appendChild(element);
	this.contentbox_resize = element;
    },
    __createButtonsElement: function() {
	if (this.contentbox_buttons) return;
	var element = Builder.node('div', {
	    "class":$A(this.classNames()).first() + '_buttons', "id":this.id + '_buttons'});
	this.contentboxTitle.appendChild(element);
	this.contentbox_buttons = element;
    },
    __createCloseElement: function() {
	if (this.contentbox_close) return;
	if (!this.contentbox_buttons) this.__createButtonsElement();
	var element = Builder.node('div', {
	    "class":$A(this.classNames()).first() + '_close', "id":this.id + '_close'});
	this.contentbox_buttons.appendChild(element);
	this.contentbox_close = element;
	this.contentbox_close.onclick = this.close.bindAsEventListener(this);
    },
    __checkTitleWidth: function() {
	return this.__checkWidth(this.contentboxTitle);
    },
    __checkHeaderWidth: function() {
	return this.__checkWidth(this.contentboxHeader);
    },
    __checkContentWidth: function() {
	return this.__checkWidth(this.contentboxContent);
    },
    __checkFooterWidth: function() {
	return this.__checkWidth(this.contentboxFooter);
    },
    __checkWidth: function(element) {
	element = $(element);
	if (!element) return 0;
	var delta = this.__horizontalPadding();
	var d;
	element.cleanWhitespace();
	if (element.childNodes.length == 1) {
            if (element.firstChild.tagName)
		d = $(element.firstChild).getDimensions().width + delta;
	} else {
	    var max = 0;
	    var cumulative = 0;
	    for (var i = 0; i < element.childNodes.length; i++) {
		var child = $(element.childNodes[i]);
		var width = child.getDimensions().width;
		if (!width) continue;
		if (child.getStyle('display') == 'inline' || child.id == this.id + '_buttons') {
		    cumulative += width;
		    max = max > cumulative ? max : cumulative;
		} else {
		    max = max > width ? max : width;
		}
	    }
	    d = max + delta;
	}
	return d;
    },
    __getRelativePointerPosition: function(evt) {
	var scroll = Position.scrollOffset(this);
	var offset = Position.cumulativeOffset(this);
	var position = scroll[0]  == 0 && scroll[1] == 0 ? offset : scroll;
	var dimension = this.getDimensions();
	var pointer = [Event.pointerX(evt), Event.pointerY(evt)];
	var se = [position[0] + dimension.width, position[1] + dimension.height];
	padding = parseInt($(this.id + '_middler').getStyle('padding-right'));

	if (pointer[0] >= se[0] - padding && pointer[0] <= se[0] && pointer[1] >= se[1] - padding && pointer[1] <= se[1]) {
	    this.setStyle({cursor: 'se-resize'});
	    this.pointerPosition = 'se';
	} else {
	    this.setStyle({cursor: 'default'});
	    this.pointerPosition = false;
	}
    },
    __setupDrag: function() {
	this.contentboxTitle.style.cursor = 'move';
	this.contentboxTitle.parentNode.style.cursor = 'move';
	this._draggable = new Draggable(this, {
	    handle:$(this.id + '_title'),
	    starteffect:null,
	    endeffect:this.__endDragCallback.bind(this)});
	this.setFocus();
	return this.observe('click', this.setFocus.bind(this));
    },
    __setupClose: function() {
	this.__createCloseElement();
	return this;
    },
    __setupResize: function() {
        this.observe('mousemove', this.__getRelativePointerPosition.bindAsEventListener(this));
	this._resizer = new Resizer(this, {
	    handle: this,
	    contentbox: this,
	    horizontal: true,
	    vertical: true,
	    maxHeight: 1000,
	    maxWidth: 1000,
	    minHeight: 70,
	    minWidth: 70,
	    resizeCallback: this.__resizeCallback.bind(this)});

        return this;
    },
    __setupModal: function() {
	if (this.modalElement) return;
	var paren = this.parentNode;
	var zIndex = parseInt(this.getStyle('z-index'));
	this.modalElement = $(Builder.node('div', {
	    id: this.id + '_modal', className: 'modal_view'
	}));
	if (this.options.closeModalOnClick)
	    this.modalElement.observe('click', this.close.bind(this));
	this.modalElement.setOpacity(this.options.modalOpacity);
	this.modalElement.setStyle({zIndex: zIndex - 1});
	var page_dims = pageDimensions();
	this.modalElement.setStyle({
	    height: page_dims.height + 'px',
	    width: page_dims.width + 'px'
	});
	paren.insertBefore(this.modalElement, this);
	Event.observe(window, 'resize', function() {
	    if (!this.modalElement) return;
	    var page_dims = pageDimensions();
	    this.modalElement.setStyle({
		height: page_dims.height + 'px',
		width: page_dims.width + 'px'
	    });
	}.bind(this));
	if (ie4 && !ie7) {
	    if (this.options.modal) {
		this.__qframe = $(Builder.node('iframe', {
		    src: "javascript: false", className: "qframe",
		    style: "width: " + page_dims.width + "px; height: " + page_dims.height + "px;"
		}));
		this.__qframe.setStyle({top: '0px', left: '0px', position: 'absolute'});
		paren.insertBefore(this.__qframe, this.modalElement);
	    }
	}
    },
    __horizontalPadding: function() {
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
    },
    __removeQuirks: function() {
	return;
	if (!ie4 || ie7) return;
	if (this.options.modal) return;
	if (this.__qframe) return;
	var dims = this.getDimensions();
	var qframe = Builder.node('iframe', {
	    src: "javascript: false", className: "qframe",
	    top: "0px", left: "0px",
	    style: "width: " + dims.width + "px; height: " + dims.height + "px;"
	});
	this.__qframe = $(qframe);
	this.insertBefore(qframe, this.firstChild);
    },
    __resizeCallback: function(element, d) {
	d = {width: parseInt(d.width), height: parseInt(d.height)};
	this.childElements().each(function($_) {
	    if ($_ != this.contentboxContent.parentNode.parentNode) {
		var dims = $_.getDimensions();
		d.height -= dims.height;
	    }
	}.bind(this));
	this.contentboxContent.setStyle({height: d.height + 'px'});
    },
    __hideQuirks: function() {
	if (!ie4 || ie7) return;
	if (this.options.modal) return;
	var problematic = ["applet", "select", "iframe"];
	var dim = this.getDimensions();
	var pos = Position.cumulativeOffset(this);
	var thisDelta = {x1: pos[0], x2: pos[0] + dim.width, y1: pos[1], y2: pos[1] + dim.height};
	for (var k = 0; k < problematic.length; k++) {
	    var pr_el = $A(document.getElementsByTagName(problematic[k]));
	    pr_el.each(function(el, $i) {
		el = $(el);
		if (el.descendantOf(this)) return;
		var pos = Position.cumulativeOffset(el);
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
    },
    __endDragCallback: function() {
	this.setFocus();
	this.__hideQuirks();
    }
});
