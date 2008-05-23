// vim: set autoindent shiftwidth=4 tabstop=8:
IWL.ComboView = Object.extend(Object.extend({}, IWL.Widget), (function () {
    function connectSignals() {
        var mouseover = function() {
            setState.call(this, this.state | IWL.ComboView.State.HOVER);
        }.bind(this);
        var mouseout = function() {
            setState.call(this, this.state & ~IWL.ComboView.State.HOVER);
        }.bind(this);
        var mousedown = function(event) {
            setState.call(this, (this.state & IWL.ComboView.State.SHOW) | IWL.ComboView.State.PRESS);
            Event.stop(event);
        }.bind(this);
        var mouseup = function(event) {
            setState.call(this, (this.state & IWL.ComboView.State.SHOW ? 0 : IWL.ComboView.State.SHOW) | IWL.ComboView.State.HOVER);
            Event.stop(event);
        }.bind(this);

        var cell = this.button.up();
        cell.signalConnect('mouseover', mouseover);
        cell.signalConnect('mouseout', mouseout);
        cell.signalConnect('mousedown', mousedown);
        cell.signalConnect('mouseup', mouseup);
        if (!this.options.editable) {
            cell = this.content.up();
            cell.signalConnect('mouseover', mouseover);
            cell.signalConnect('mouseout', mouseout);
            cell.signalConnect('mousedown', mousedown);
            cell.signalConnect('mouseup', mouseup);
        }
    }

    function setContent(cellTemplate) {
        this.content.innerHTML = generateContentTemplate.call(this).evaluate(cellTemplate || {});
    }

    function generateContentTemplate() {
        /* Individual rows can't be dragged. Each node has to be a full table */
        var node = ['<table cellpadding="0" cellspacing="0" class="comboview_node"><tbody><tr>'];

        for (var i = 0, l = this.model.getColumnCount(); i < l; i++) {
            var classNames = ['comboview_column', 'comboview_column' + i], width = '';
            if (this.options.columnClass[i])
                classNames.push(this.options.columnClass[i]);
            if (i == 0) classNames.push('comboview_column_first');
            if (i == l - 1) classNames.push('comboview_column_last');
            if (this.options.columnWidth[i])
                width = ' style="width: ' + this.options.columnWidth[i] + 'px;"';
            node.push('<td class="', classNames.join(' '), '"', width, '>#{column', i, '}</td>');
        }
        node.push('</tr></tbody></table>');

        return new Template(node.join(''));
    }

    function generateNodeTemplate(flat) {
        /* Individual rows can't be dragged. Each node has to be a full table */
        var node = ['<table cellpadding="0" cellspacing="0" class="comboview_node #{nodePosition}" iwl:nodePath="#{nodePath}"><tbody><tr>'];

        for (var i = 0, l = this.model.getColumnCount(); i < l; i++) {
            var classNames = ['comboview_column', 'comboview_column' + i], width = '';
            if (this.options.columnClass[i])
                classNames.push(this.options.columnClass[i]);
            if (i == 0) classNames.push('comboview_column_first');
            if (i == l - 1) classNames.push('comboview_column_last');
            if (this.options.columnWidth[i])
                width = ' style="width: ' + this.options.columnWidth[i] + 'px;"';
            node.push('<td class="', classNames.join(' '), '"', width, '>#{column', i, '}</td>');
        }
        node.push('<td class="comboview_parental_arrow_column">#{parentalArrow}</td>');
        node.push('</tr></tbody></table>');

        return new Template(node.join(''));
    }

    function onDataLoad(event) {
        var flat = this.model.isFlat();
        var template = generateNodeTemplate.call(this, flat)
        createNodes.call(this, this.model.getRootNodes(), template, flat);
        this.setActive(this.options.initialPath);
    }

    function cellTemplateRenderer(node) {
        var values = node.getValues(), cellTemplate = {};
        for (var i = 0, l = values.length; i < l; i++) {
            var render = this.options.cellAttributes[i] && this.options.cellAttributes[i].renderTemplate;
            if (render) {
                render = new Template(render);
                cellTemplate['column' + i] = Object.isObject(values[i])
                    ? render.evaluate(values[i])
                    : render.evaluate({cellValue: values[i]});
            } else {
                if (this.model.getColumnType(i) == IWL.TreeModel.DataTypes.STRING)
                    cellTemplate['column' + i] = values[i].toString();
                else if (this.model.getColumnType(i) == IWL.TreeModel.DataTypes.INT)
                    cellTemplate['column' + i] = parseInt(values[i])
                else if (this.model.getColumnType(i) == IWL.TreeModel.DataTypes.FLOAT)
                    cellTemplate['column' + i] = parseFloat(values[i])
                else if (this.model.getColumnType(i) == IWL.TreeModel.DataTypes.BOOLEAN)
                    cellTemplate['column' + i] = values[i].toString();
                else if (this.model.getColumnType(i) == IWL.TreeModel.DataTypes.COUNT) {
                    cellTemplate['column' + i] = node.getIndex() + 1 + (this.model.options.offset || 0);
                }
            }
        }
        return cellTemplate;
    }

    function setNodeAttributes(container, element, node) {
        node.viewRow = element;
        node.viewContainer = container;
        node.viewCells = $A(element.rows[0].cells);
        var childContainer = node.viewChildContainer;

        element.signalConnect('dom:mouseenter', function(event) {
            element.addClassName('comboview_node_highlight');
            this.currentNodeHighlight = node;
            if (!childContainer || !Object.isElement(childContainer.parentNode) || !childContainer.visible())
                container.childContainers.each(function(c) { popDown.call(this, c) }.bind(this));
        }.bind(this));
        element.signalConnect('dom:mouseleave', function(event) {
            element.removeClassName('comboview_node_highlight');
        }.bind(this));

        if (node.hasChildren() > 0 && childContainer) {
            childContainer.parentRow = element;
            element.signalConnect('dom:mouseenter', function(event) {
                clearTimeout(childContainer.popDownDelay);
                /* Race condition by incorrect event sequence in IE */
                popUp.bind(this, childContainer).delay(0.001);
            }.bind(this));
            element.signalConnect('dom:mouseleave', function(event) {
                childContainer.popDownDelay = popDown.bind(this, childContainer).delay(this.options.popDownDelay);
            }.bind(this));
            childContainer.signalConnect('dom:mouseenter', function(event) {
                clearTimeout(childContainer.popDownDelay);
                clearTimeout(childContainer.parentContainer.popDownDelay);
            }.bind(this));
            childContainer.signalConnect('dom:mouseleave', function(event) {
                childContainer.popDownDelay = popDown.bind(this, childContainer).delay(this.options.popDownDelay);
            }.bind(this));
        }
    }

    function cellFunctionRenderer(element, values) {
        for (var i = 0, l = values.length; i < l; i++) {
            var attributes = this.options.cellAttributes[i];
            var render = attributes && attributes.renderFunction;
            if (!Object.isFunction(render)) continue;
            render.call(attributes.renderInstance || this, element.rows[0].cells[i], this.model.getColumnType(i), values[i], node);
        }
    }

    function createNodes(nodes, template, flat) {
        var html = [];
        var container;
        if (nodes[0] && nodes[0].parentNode) {
            var path = nodes[0].parentNode.getPath().toString();
            container = this.containers[path];
            if (!container)
                container = new Element('div', {className: 'comboview_node_container'});
            this.containers[path] = container;

            nodes[0].parentNode.viewChildContainer = container;
            container.parentContainer = nodes[0].parentNode.parentNode
                                     && nodes[0].parentNode.parentNode.viewChildContainer
                ? nodes[0].parentNode.parentNode.viewChildContainer
                : this.container;
            container.parentContainer.childContainers.push(container);
        } else {
            container = this.container;
            if (!container) {
                container = new Element('div', {className: 'comboview_node_container'});
                container.registerFocus();
                container.keyLogger(keyEventsCB.bindAsEventListener(this));
            }
            if (this.pageControl && !container.pageContainer) {
                var pageContainer = new Element('div', {className: 'comboview_page_container'});
                pageContainer.appendChild(container);
                pageContainer.appendChild(this.pageControl);
                this.pageControl.setStyle({position: '', left: ''});
                container.pageContainer = pageContainer;
            }
            this.container = container;
        }
        container.childContainers = [];
        for (var i = 0, l = nodes.length, node = nodes[0]; i < l; node = nodes[++i]) {
            var cellTemplate = cellTemplateRenderer.call(this, node);
            if (!flat && node.hasChildren() > 0) {
                cellTemplate.parentalArrow = '<div class="comboview_parental_arrow"></div>';
                createNodes.call(this, node.children(), template);
            }

            if (i + 1 == l && i == 0)
                cellTemplate.nodePosition = 'comboview_node_first comboview_node_last'
            else if (i == 0)
                cellTemplate.nodePosition = 'comboview_node_first'
            else if (i + 1 == l)
                cellTemplate.nodePosition = 'comboview_node_last'
            cellTemplate.nodePath = node.getPath().toJSON();
            html.push(template.evaluate(cellTemplate));
        };
        container.innerHTML = html.join('');
        var children = container.childElements();
        for (var i = 0, l = nodes.length; i < l; i++) {
            setNodeAttributes.call(this, container, children[i], nodes[i]);
            cellFunctionRenderer.call(this, children[i], nodes[i].getValues());
        }
    }

    function setState(state) {
        if (this.pageChanging) return;
        this.state = state;
        var classNames = ['comboview_button'];
        if (state == (IWL.ComboView.State.SHOW | IWL.ComboView.State.HOVER)) {
            classNames.push('comboview_button_on_hover');
        } else if (state == (IWL.ComboView.State.SHOW | IWL.ComboView.State.PRESS)) {
            classNames.push('comboview_button_on_press');
        } else if (state == IWL.ComboView.State.SHOW) {
            classNames.push('comboview_button_on');
        } else if (state == (IWL.ComboView.State.HOVER)) {
            classNames.push('comboview_button_off_hover');
        } else if (state == (IWL.ComboView.State.PRESS)) {
            classNames.push('comboview_button_off_press');
        } else if (!state) {
            classNames.push('comboview_button_off');
        }
        state & IWL.ComboView.State.SHOW ? popUp.call(this) : popDown.call(this);
        this.button.className = classNames.join(' ');
        this.emitSignal('iwl:state_change', state);
    }

    function setupScrolling(container, page) {
        var width = container.getStyle('width');
        var height = container.getStyle('height');
        if (this.options.maxHeight > parseFloat(height)) return;
        var scrollbar = document.viewport.getScrollbarSize();
        var new_width = parseInt(width) + scrollbar;
        if (Prototype.Browser.Opera)
            container.setStyle({width: new_width + 'px', height: this.options.maxHeight + 'px', overflow: 'auto'});
        else
            container.setStyle({width: new_width + 'px', height: this.options.maxHeight + 'px', overflowY: 'scroll'});
        if (page) {
            page.setStyle({width: container.getWidth()
                + parseFloat(container.getStyle('margin-left') || 0)
                + parseFloat(container.getStyle('margin-right') || 0) + 'px'
            });
        }
    }


    function popUp(container) {
        var container = Object.isElement(container)
            ? container : this.container.pageContainer || this.container;
        var inner = this.container.pageContainer ? this.container : container;
        if (!container) return;
        if (container.popped) return;
        container.setStyle({display: 'block', visibility: 'hidden'});
        container.popped = true;
        if (!Object.isElement(container.parentNode))
            (container.parentContainer || this).insert({after: container});

        var width = document.viewport.getWidth() + document.viewport.getScrollOffsets().left,
            container_width = this.container.getWidth();
        if (container.parentRow) {
            var parent_position = [parseFloat(container.parentContainer.getStyle('left')), parseFloat(container.parentContainer.getStyle('top'))],
                view_width = this.getWidth();
            if (parent_position[0] + 2 * container_width > width) {
                if (parent_position[0] - view_width > 5)
                    parent_position[0] -= view_width;
                else {
                    parent_position[0] += 20;
                    parent_position[1] += container.parentRow.getHeight() * 7 / 8;
                }
            } else parent_position[0] += this.content.down('.comboview_node').getWidth();
            parent_position[1] += (container.parentRow.offsetTop - container.parentContainer.scrollTop);
        } else {
            var parent_position = this.getStyle('position') == 'absolute'
                ? this.cumulativeOffset()
                : this.positionedOffset();
            parent_position[1] += this.getHeight();
        }
        container.setStyle({
            left: parent_position[0] + 'px',
            top: parent_position[1] + 'px'
        });

        if (!container.initialized) {
            var table = inner.down('.comboview_node');
            inner.style.width = table.getWidth()
                + parseFloat(table.getStyle('margin-left') || 0)
                + parseFloat(table.getStyle('margin-right') || 0) + 'px';

            if (this.options.maxHeight)
                setupScrolling.call(this, inner, this.container.pageContainer);

            container.initialized = true;

            document.observe('click', function(event) {
                var inside = Event.checkElement(event, container);
                if (!inside && !Event.checkElement(event, this))
                    return this.popDown();
                else if (inside) {
                    var element = Event.element(event).up('.comboview_node');
                    if (!element || element.descendantOf(this)) return;
                    var path = element.readAttribute('iwl:nodePath').evalJSON();
                    this.setActive(path);
                    return this.popDown();
                }
            }.bind(this));
        }
        container.setStyle({visibility: 'visible'});
    }

    function popDown(container) {
        var container = Object.isElement(container)
            ? container
            : this.container.pageContainer || this.container;
        if (!container) return;
        (container == this.container.pageContainer ? this.container : container).childContainers.each(
            function(c) { popDown.call(this, c) }.bind(this)
        );
        if (!container.popped) return;
        container.style.display = 'none';
        container.popped = false;
    }

    function changeHighlight(current, node) {
        if (current)
            current.viewRow.removeClassName('comboview_node_highlight');
        if (node)
            node.viewRow.addClassName('comboview_node_highlight');
        this.currentNodeHighlight = node;
    }

    function keyEventsCB(event) {
        var current = this.currentNodeHighlight;
        var row = current ? current.viewRow : null;
        if (!row || !row.hasClassName('comboview_node_highlight'))
            return;
        var keyCode = Event.getKeyCode(event);
        var row;
        if (![Event.KEY_UP, Event.KEY_DOWN, Event.KEY_RETURN].include(keyCode)) return;
        var nodes = this.model.toArray(), node;

        if (keyCode == Event.KEY_UP)  {
            if (node = nodes[nodes.indexOf(current) - 1])
                changeHighlight.call(this, current, node);
            Event.stop(event);
        } else if (keyCode == Event.KEY_DOWN) {
            if (node = nodes[nodes.indexOf(current) + 1])
                changeHighlight.call(this, current, node);
            Event.stop(event);
        } else if (keyCode == Event.KEY_RETURN) {
            this.setActive(current);
            this.popDown();
        }
    }

    function initializeClassRenderers() {
        for (var i = 0, l = this.options.cellAttributes.length; i < l; i++) {
            var renderClass = this.options.cellAttributes[i].renderClass;
            if (!renderClass) continue;
            var klass = renderClass.name.objectize();
            if (!Object.isFunction(klass)) continue;
            var instance = new klass(renderClass.options);
            if (Object.isFunction(instance.render)) {
                this.options.cellAttributes[i].renderFunction = instance.render;
                this.options.cellAttributes[i].renderInstance = instance;
            }
        }
    }

    function onPageChanging() {
        this.pageChanging = true;
        IWL.View.disable({element: this.container.pageContainer});
    }

    function onPageChange() {
        IWL.View.enable();
        this.pageChanging = undefined;
        if (this.popDownRequest) {
            this.popDownRequest = undefined;
            this.popDown();
        }
    }

    return {
        /**
         * Pops up (shows) the dropdown list
         * @returns The object
         * */
        popUp: function() {
            if (this.state & IWL.ComboView.State.SHOW) return;
            setState.call(this, this.state | IWL.ComboView.State.SHOW);
        },
        /**
         * Pops down (hides) the dropdown list
         * @returns The object
         * */
        popDown: function() {
            if (!(this.state & IWL.ComboView.State.SHOW)) return;
            if (this.pageChanging) {
                this.popDownRequest = true;
                return this;
            }
            setState.call(this, (this.state & ~IWL.ComboView.State.SHOW));
        },
        /**
         * Sets the active item of the ComboView
         * @param path The path (or index for flat models) of the item to be set as active
         * @returns The object
         * */
        setActive: function(path) {
            var node;
            if (path instanceof IWL.TreeModel.Node) {
                node = path;
                this.selectedPath = node.getPath();
            } else {
                this.selectedPath = path;
                if (!Object.isArray(path)) path = [path];
                node = this.model.getNodeByPath(path) || this.model.getFirstNode();
            }
            if (!node) return;
            this.values = node.getValues();
            var cellTemplate = cellTemplateRenderer.call(this, node);
            setContent.call(this, cellTemplate);

            return this.emitSignal('iwl:change', this.values);
        },
        /**
         * @returns The active item of the ComboView
         * */
        getActive: function() {
            return this.selectedPath;
        },

        _init: function(id, model) {
            this.options = Object.extend({
                columnWidth: [],
                columnClass: [],
                cellAttributes: [],
                initialPath: [0],
                maxHeight: 400
            }, arguments[2]);
            if (Object.keys(model.options.columnTypes).length)
                IWL.TreeModel.overrideDefaultDataTypes(model.options.columnTypes);
            this.model = new IWL.TreeModel(model.columns, model);
            this.button = this.down('.comboview_button');
            this.content = this.down('.comboview_content');
            this.contentColumns = [];
            this.containers = {};
            if (!this.options.popDownDelay)
                this.options.popDownDelay = 0.3;
            if (this.options.pageControl) {
                this.pageControl = $(this.options.pageControl);
                this.pageControl.signalConnect('iwl:current_page_is_changing', onPageChanging.bind(this));
                this.pageControl.signalConnect('iwl:current_page_change', onPageChange.bind(this));
            }
            if (this.pageControl && this.options.pageControlEventName)
                this.pageControl.bindToWidget($(this.model.options.id), this.options.pageControlEventName);

            connectSignals.call(this);
            setContent.call(this);

            this.state = 0;
            this.emitSignal('iwl:load');

            if (window.attachEvent)
                window.attachEvent("onunload", function() { this.model = null });

            initializeClassRenderers.call(this);
            onDataLoad.call(this, null, this.model.options);
            var callback = onDataLoad.bind(this);
            this.model.signalConnect('iwl:load_data', callback);
            this.model.signalConnect('iwl:sort_column_change', callback);

            this.emitSignal('iwl:load');
        }
    }
})());

IWL.ComboView.State = (function () {
    var index = 0;

    return {
        SHOW: 1 << index++,
        HOVER: 1 << index++,
        PRESS: 1 << index++
    }
})();
