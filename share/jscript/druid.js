// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.Druid is a class for adding step-separated widgets
 * @extends IWL.Widget
 * */
IWL.Druid = Object.extend(Object.extend({}, IWL.Widget), (function () {
    function createPage(final) {
        var class_name = $A(this.classNames()).first() + '_page';
        var page = new Element('div', {
            'class': class_name,
            id: class_name + '_' + Math.random()
        });
        page.style.display = 'none';
        if (final)
            page.setAttribute('iwl:druidFinalPage', 1);

        return IWL.Druid.Page.create(page, this);
    }

    function buttonLoad(count) {
        if (--count > 0) return;
        this.nextText = this.nextButton.getLabel();
        this._refreshButtons();
    }

    return {
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
            if (!(page = $(page)) && !(page = this.currentPage))
                return;
            page.remove();
            return this;
        },
        /**
         * Appends a new page to the druid
         * @param {Boolean} final True if the new page should be the final page in the druid
         * @returns The created page
         * */
        appendPage: function(final) {
            var page = createPage.call(this, final);
            this.pageContainer.appendChild(page);
            this.pages.push(page);
            this._refreshButtons();

            return page;
        },
        /**
         * Prepends a new page to the druid
         * @param {Boolean} final True if the new page should be the final page in the druid
         * @returns The created page
         * */
        prependPage: function(final) {
            var page = createPage.call(this, final);
            this.pageContainer.insertBefore(page, this.pages[0]);
            this.pages.unshift(page);
            this._refreshButtons();

            return page;
        },
        /**
         * Replaces the page before the given one
         * @param {Boolean} final True if the new page should be the final page in the druid
         * @param p The new page should be inserted before this one. If omited the current page is used
         * @returns The created page
         * */
        replacePageBefore: function(final, p) {
            var page = createPage.call(this, final);
            if (!p || this.pages.indexOf(p) == -1)
                p = this.currentPage;
            var i = this.pages.indexOf(p);
            if (i >= 0) {
                if (i == 0) {
                    this.pageContainer.insertBefore(page, this.pages[0]);
                    this.pages.unshift(page);
                } else {
                    var before_p = p.prevPage();
                    this.pageContainer.replaceChild(page, before_p);
                    if (before_p == this.currentPage)
                        page.setSelected(true, true);

                    this.pages[i - 1] = page;
                }
            }

            this._refreshButtons();
            return page;
        },
        /**
         * Replaces the page after the given one or appends a new one
         * @param {Boolean} final True if the new page should be the final page in the druid
         * @param p The new page should be inserted after this one. If omited the current page is used
         * @returns The created page
         * */
        replacePageAfter: function(final, p) {
            var page = createPage.call(this, final);
            if (!p || this.pages.indexOf(p) == -1)
                p = this.currentPage;
            var i = this.pages.indexOf(p);
            if (i >= 0) {
                var after_p = p.nextPage();
                if (after_p) {
                    this.pageContainer.replaceChild(page, after_p);
                    if (after_p == this.currentPage)
                        page.setSelected(true, true);
                } else {
                    this.pageContainer.appendChild(page);
                }

                this.pages[i + 1] = page;
            }

            this._refreshButtons();
            return page;
        },
        /**
         * Checkes whether the given page is the final page of the druid
         * @param page The page object. If not specified, the current page is used
         * @returns True if the page is final
         * @type Boolean
         * */
        pageIsFinal: function(page) {
            page = $(page) || this.currentPage;
            if (!page) return;
            return page.isFinal();
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
            this.okButton = $(this.id + '_ok_button');
            this.backButton = $(this.id + '_back_button');
            this.nextButton = $(this.id + '_next_button');
            if (!this.nextButton) {
                setTimeout(this._init.apply.bind(this, arguments), 500);
                return;
            }
            this.pageContainer = this.down();
            this.currentPage = this.pageContainer.select('.' +
                    $A(this.classNames()).first() + '_page_selected')[0];
            this.finishText = unescape(text);
            this.errorPage = new Element('div', {className: $A(this.classNames()).first() + '_page_error'});
            this.pageContainer.appendChild(this.errorPage);
            this.pages = [];
            this.pageContainer.childElements().each(function($_) {
                if ($_.hasClassName('druid_page'))
                    this.pages.push(IWL.Druid.Page.create($_, this));
            }.bind(this));
            
            var count = 3;
            this.okButton.signalConnect('iwl:init', buttonLoad.bind(this, count));
            this.backButton.signalConnect('iwl:init', buttonLoad.bind(this, count));
            this.nextButton.signalConnect('iwl:init', buttonLoad.bind(this, count));

            this.nextButton.signalConnect('click', function() {
                if (this.currentPage.isFinal()) {
                    if (this.nextButton.finish)
                        this.nextButton.finish.apply(this.nextButton.finish_this);
                    else
                       this.currentPage.emitEvent('IWL-Druid-Page-final', {},
                           {id: this.currentPage.id}); 
                    return;
                }
                if (this.currentPage.hasEvent('IWL-Druid-Page-next'))
                    this.currentPage.emitEvent('IWL-Druid-Page-next', {},
                        {id: this.currentPage.id}); 
                else {
                    var page = this.currentPage.nextPage();
                    if (page) page.setSelected(true);
                }
            }.bind(this));
            this.backButton.signalConnect('click', function () {
                if (this.currentPage.hasEvent('IWL-Druid-Page-previous'))
                    this.currentPage.emitEvent('IWL-Druid-Page-previous', {},
                        {id: this.currentPage.id}); 
                else {
                    var page = this.currentPage.prevPage();
                    if (page) page.setSelected(true, true);
                }
            }.bind(this));
            this.okButton.signalConnect('click', function() {
                this.currentPage._restorePage();
                if (this.currentPage._handler)
                    this.currentPage['handlers'][this.currentPage._handler.name] = this.currentPage._handler.value;
            }.bind(this));
        },
        _refreshButtons: function() {
            var pos = this.pages.indexOf(this.currentPage);
            var next = true;
            var back = true;
           
            if (pos == 0 && !this.currentPage.hasEvent('IWL-Druid-Page-previous'))
                back = false;
            if (pos == this.pages.length - 1 && !this.currentPage.hasEvent('IWL-Druid-Page-next'))
                next = false;
            
            if (this.currentPage.isFinal()) {
                next = true;
                this.nextButton.setLabel(this.finishText);
            } else
                this.nextButton.setLabel(this.nextText);

            this.backButton.setStyle({visibility: back ? 'visible' : 'hidden'});
            this.nextButton.setStyle({visibility: next ? 'visible' : 'hidden'});
        }
    }
})());

/**
 * @class IWL.Druid.Page is a class for creating druid pages
 * @extends IWL.Widget
 * */
IWL.Druid.Page = Object.extend(Object.extend({}, IWL.Widget), (function () {
    function buttonResponse(new_page, json, event_type) {
        var extras = json.extras;
        if (extras.deter) {
            this.druid.errorPage.update(unescape(json.data));
            this._defaultHeight = this.getStyle('height');
            this.__expression = extras.expression;
            showError.call(this);
            var event_name = 'IWL-Druid-Page-' + event_type;
            this._handler = {name: event_name, value: this.hasEvent(event_name)};
            return;
        }

        var new_id = extras.newId;
        if (new_id)
            new_page.id = new_id;
        new_page.update(unescape(json.data));

        ["final", "next", "previous"].each(function(type) {
            if (!(type in extras)) return;
            if (!(extras[type]['url'])) return;
            var options = Object.extend(extras[type]['options'] || {}, 
                {method: type == 'next' 
                         ? '_nextResponse' 
                         : type == 'previous' 
                           ? '_previousResponse' : null
                });
            new_page.registerEvent('IWL-Druid-Page-' + type, extras[type]['url'], 
                extras[type]['params'], options);
        });
        new_page.setSelected(true);
    }

    function hidePage(element, after_finish) {
        if (!(element = $(element))) return;
        if (element.hidden === true) return;
        if (!after_finish) after_finish = Prototype.emptyFunction;
        element._defaultOverflow = element.getStyle('overflow');
        element.setStyle({overflow: 'hidden'});
        var options = {scaleContent: false, transition: Effect.Transitions.sinoidal, duration: 0.6,
            scaleX: false, afterFinish: after_finish};
        new Effect.Scale(element, 0 , options);
        element.hidden = true;
    }

    function showPage(element) {
        if (!(element = $(element))) return;
        if (element.hidden === false) return;
        var options = {scaleX: false, scaleFrom: 0, scaleContent: false, duration: 0.6,
                transition: Effect.Transitions.sinoidal, scaleMode: 'content',
                afterFinish: function() {
                    if (element._defaultOverflow)
                        element.setStyle({overflow: element._defaultOverflow});
                    if (element._defaultHeight)
                        element.setStyle({height: element._defaultHeight});
                }
            };
        new Effect.Scale(element, 100 , options);
        element.hidden = false;
    }

    function showError() {
        hidePage.call(this, this, function() {
                this.druid.okButton.setStyle({visibility: 'visible'});
                this.druid.backButton.setStyle({visibility: 'hidden'});
                this.druid.nextButton.setStyle({visibility: 'hidden'});
            }.bind(this));
        showPage.call(this, this.druid.errorPage);
    }

    return {
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
                this.druid._refreshButtons();

                this.druid.emitSignal('iwl:current_page_change', this);
                this.emitSignal('iwl:select');
            } else {
                if (!this.isSelected()) return;
                var callback;
                if (!ignoreCheck) {
                    var control_params = this.getControlElementParams();
                    if (this.check.callback) {
                        if (window[this.check.callback]) {
                            if (!this.check.collect) control_params = null;
                            var retval = window[this.check.callback].call(this, this.check.param, control_params);
                        }
                        if (!retval) return;
                    }
                }
                this.removeClassName(base_class + '_selected');
                this.hide();
                this.druid.currentPage = null;

                if (!arguments[2]) {
                    var prev = this.prevPage() || this.nextPage();
                    if (prev) prev.setSelected(true);
                }
                this.emitSignal('iwl:unselect');
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
         * Checks whether the page is the final page in the druid
         * @returns True if the page is the final one
         * @type Boolean
         * */
        isFinal: function() {
            return !!this.readAttribute('iwl:druidFinalPage');
        },
        /**
         * @returns The previous page
         * */
        prevPage: function() {
            return this.druid.pages[this.druid.pages.indexOf(this) - 1];
        },
        /**
         * @returns The next page, or undefined if this is the final page
         * */
        nextPage: function() {
            if (this.isFinal()) return;
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
            this.druid._refreshButtons();
            this.emitSignal('iwl:remove');
            return this;
        },

        _init: function(id, druid) {
            this.druid = druid;
            this.check = {
                callback: this.readAttribute('iwl:druidCheckCallback'),
                param: unescape(this.readAttribute('iwl:druidCheckParam') || '[]').evalJSON(),
                collect: false
            }
            if (this.check.param) {
                this.check.collect = this.check.param.pop();
                this.check.param = this.check.param.shift();
            }
        },
        _restorePage: function() {
            showPage.call(this, this);
            hidePage.call(this, this.druid.errorPage, function() {
                    if (this.__expression)
                        (function () {
                            try { eval(this.__expression) } catch(e) {};
                        }).call(this);
                    this.__expression = null;
                    this.druid.okButton.setStyle({visibility: 'hidden'});
                    this.druid._refreshButtons();
                }.bind(this));
        },
        _previousResponse: function(json, params, options) {
            var final = !!json.extras.final;
            buttonResponse.call(this, this.druid.replacePageBefore(final, this), json, 'previous');
        },
        _nextResponse: function(json, params, options) {
            var final = !!json.extras.final;
            buttonResponse.call(this, this.druid.replacePageAfter(final, this), json, 'next');
        }
    }
})());

/* Deprecated */
var Druid = IWL.Druid;
var Page = IWL.Druid.Page;
