// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class Druid is a class for adding step-separated widgets
 * @extends Widget
 * */
var Druid = {};
Object.extend(Object.extend(Druid, Widget), {
    /**
     * Selects the given page
     * @param page The page to select
     * @param {Boolean} ignoreCheck True if the check callback should be skipped
     * @returns The object
     * */
    selectPage: function(page, ignoreCheck) {
	page = $(page);
        if (!page) return;
	page.setSelected(true, ignoreCheck);
	return this;
    },
    /**
     * Returns the next page, relative to the given one
     * @param page The page object. If not specified, the current page is used
     * @returns The next page 
     * */
    getNextPage: function(page) {
	page = $(page) || this.currentPage;
        if (!page) return;
	return page.nextPage();
    },
    /**
     * Returns the previous page, relative to the given one
     * @param page The page object. If not specified, the current page is used
     * @returns The previous page 
     * */
    getPrevPage: function(page) {
	page = $(page) || this.currentPage;
        if (!page) return;
	return page.prevPage();
    },
    /**
     * Returns the current page
     * @returns The current page 
     * */
    getCurrentPage: function() {
	return this.currentPage;
    },
    /**
     * Removes the given page
     * @param page The page object. If not specified, the current page is used
     * @returns The object 
     * */
    removePage: function(page) {
	page = $(page) || this.currentPage;
	if (!page) return;
	page.remove();
	return this;
    },
    /**
     * Appends a new page to the druid
     * @param {Boolean} last True if the new page should be the last page in the druid
     * @returns The created page
     * */
    appendPage: function(last) {
	var page = Builder.node('div', {
	    'class': $A(this.classNames()).first() + '_page',
	    id: this.id + '_page_' + this.pages.length
	});
	page.style.display = 'none';
        if (last)
            page.setAttribute('iwl:druidLastPage', 1);
	this.pageContainer.appendChild(page);
	this.pages.push(page);
        this.nextButton.setStyle({visibility: 'visible'});
        return Page.create(page, this);
    },
    /**
     * Checkes whether the given page is the last page of the druid
     * @param page The page object. If not specified, the current page is used
     * @returns True if the page is last
     * @type Boolean
     * */
    pageIsLast: function(page) {
	page = $(page) || this.currentPage;
	if (!page) return;
	return page.isLast();
    },
    /**
     * Sets a callback function to be called when the 'finish' button is pressed
     * @param callback A function name or pointer, which will be called
     * @param thisArg The calling object
     * @returns The object
     * */
    setFinish: function(callback, thisArg) {
	if (typeof callback == 'string')
	    this.nextButton.finish = window[callback];
	else
	    this.nextButton.finish = callback;
        this.nextButton.finish_this = thisArg;
	return this;
    },

    _init: function (id, text) {
	this.backButton = $(this.id + '_back_button');
        this.nextButton = $(this.id + '_next_button');
	if (!this.nextButton) {
	    this.__timeout = setTimeout(this._init.apply.bind(this, arguments), 500);
	    return;
	}
	this.pageContainer = this.down();
	this.currentPage = this.pageContainer.getElementsBySelector('.' +
		$A(this.classNames()).first() + '_page_selected')[0];
        this.finishText = unescape(text);
        this.nextText = this.nextButton.getLabel();
	this.pages = [];
	this.pageContainer.childElements().each(function($_) {
	    if ($_.hasClassName('druid_page'))
		this.pages.push(Page.create($_, this));
	}.bind(this));

        if (this.currentPage == this.pages[0])
            this.backButton.setStyle({visibility: 'hidden'});

	this.nextButton.signalConnect('click', function() {
	    if (this.currentPage.isLast()) {
		this.nextButton.finish.apply(this.nextButton.finish_this);
		return;
	    }
	    var page = this.currentPage.nextPage();
	    if (page) page.setSelected(true);
	}.bind(this));
	this.backButton.signalConnect('click', function () {
	    var page = this.currentPage.prevPage();
	    if (page) page.setSelected(true, true);
	}.bind(this));
    }
});

/**
 * @class Page is a class for creating druid pages
 * @extends Widget
 * */
var Page = {};
Object.extend(Object.extend(Page, Widget), {
    /**
     * Sets whether the page is selected
     * @param {Boolean} select True if the page should be selected
     * @param {Boolean} ignoreCheck True if the check callback should be skipped
     * @returns The object 
     * */
    setSelected: function(select, ignoreCheck) {
	var base_class = $A(this.classNames()).first();
	if (select) {
	    if (this.isSelected()) return;

	    if (this.druid.currentPage) {
		if (!this.druid.currentPage.setSelected(false, ignoreCheck, true))
		    return;
	    }
	    this.addClassName(base_class + '_selected');
	    this.show();
	    this.druid.currentPage = this;
	    this._buttonCorrection();

	    this.druid.emitSignal('current_page_change', this);
	    this.emitSignal('select');
	} else {
	    if (!this.isSelected()) return;
	    var callback;
	    if (this.check.callback && !ignoreCheck) {
		if (window[this.check.callback]) var retval = window[this.check.callback].call(this, this.check.param);
		if (!retval) return;
	    }
	    this.removeClassName(base_class + '_selected');
	    this.hide();
	    this.druid.currentPage = null;

	    if (!arguments[2]) {
		var prev = this.prevPage() || this.nextPage();
		if (prev) prev.setSelected(true);
	    }
	    this.emitSignal('unselect');
	}
	return this;
    },
    /**
     * Checks whether the page is selected
     * @returns True if the page is selected
     * @type Boolean
     * */
    isSelected: function() {
	return this.hasClassName($A(this.classNames()).first() + '_selected');
    },
    /**
     * Checks whether the page is the last page in the druid 
     * @returns True if the page is the last one
     * @type Boolean
     * */
    isLast: function() {
	return !!this.readAttribute('iwl:druidLastPage');
    },
    /**
     * @returns The previous page
     * */
    prevPage: function() {
	return this.druid.pages[this.druid.pages.indexOf(this) - 1];
    },
    /**
     * @returns The next page
     * */
    nextPage: function() {
	if (this.isLast()) return;
	return this.druid.pages[this.druid.pages.indexOf(this) + 1];
    },
    /**
     * Removes the page
     * @returns The object 
     * */
    remove: function() {
	this.setSelected(false);
	this.parentNode.removeChild(this);
	this.druid.pages = this.druid.pages.without(this);
	this.druid.currentPage._buttonCorrection();
	this.emitSignal('remove');
	return this;
    },

    _init: function(id, druid) {
	this.druid = druid;
	this.check = {
	    callback: this.readAttribute('iwl:druidCheckCallback'),
	    param: unescape(this.readAttribute('iwl:druidCheckParam') || '[]').evalJSON()
	}
	if (this.check.param) this.check.param = this.check.param.shift();
    },
    _buttonCorrection: function() {
	var prev = this.prevPage();
	var next = this.nextPage();
	var is_last = this.isLast();
	if (next && !is_last) {
	    this.druid.nextButton.setStyle({visibility: 'visible'});
	    this.druid.nextButton.setLabel(this.druid.nextText);
	} else if (is_last) {
	    this.druid.nextButton.setStyle({visibility: 'visible'});
	    this.druid.nextButton.setLabel(this.druid.finishText);
	} else {
	    this.druid.nextButton.setStyle({visibility: 'hidden'});
	}

	if (prev) this.druid.backButton.setStyle({visibility: 'visible'});
	else this.druid.backButton.setStyle({visibility: 'hidden'});
    }
});
