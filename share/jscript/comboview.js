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
        this.content.update(generateNodeTemplate.call(this, true, true).evaluate(cellTemplate || {}));
    }

    function generateNodeTemplate(flat, content) {
        /* Individual rows can't be dragged. Each node has to be a full table */
        var node = ['<table cellpadding="0" cellspacing="0" class="comboview_node #{nodePosition}" iwl:nodePath="#{nodePath}"><tbody><tr>'];

        for (var i = 0, l = this.model.getColumnCount(); i < l; i++) {
            var classNames = ['comboview_column', 'comboview_column' + i], width = '';
            if (this.options.columnClass[i])
                classNames.push(this.options.columnClass[i]);
            if (i == 0) classNames.push('comboview_column_first');
            else if (i == l - 1) classNames.push('comboview_column_last');
            if (this.options.columnWidth[i])
                width = ' style="width: ' + this.options.columnWidth[i] + 'px;"';
            node.push('<td class="', classNames.join(' '), '"', width, '>#{column', i, '}</td>');
        }
        if (!content)
            node.push('<td class="comboview_parental_arrow_column">#{parentalArrow}</td>');
        node.push('</tr></tbody></table>');

        return new Template(node.join(''));
    }

    function onDataLoad(event, options) {
        var flat = this.model.isFlat();
        var template = generateNodeTemplate.call(this, flat)
        createNodes.call(this, this.model.getRootNodes(), template, flat);
        this.setActive(this.options.initialPath);
    }

    function cellTemplateRenderer(values) {
        var cellTemplate = {};
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
                else if (this.model.getColumnType(i) == IWL.TreeModel.DataTypes.CHECKBOX)
                    cellTemplate['column' + i] = '<input type="checkbox" value="' + values[i] + '"/>';
                else if (this.model.getColumnType(i) == IWL.TreeModel.DataTypes.RADIO)
                    cellTemplate['column' + i] = '<input type="radio" value="' + values[i] + '" name="comboview_radio_group"/>';
                else if (this.model.getColumnType(i) == IWL.TreeModel.DataTypes.COUNT) {
                    var count = 0;
                    this.model.each(function(n) { count++; if (n == node) throw $break; });
                    cellTemplate['column' + i] = count;
                }
            }
        }
        return cellTemplate;
    }

    function setNodeAttributes(container, element, node) {
        node.viewRow = element;
        node.viewContainer = container;
        node.viewCells = $A(element.rows[0].cells);
        if (node.hasChildren() > 0 && node.viewChildContainer) {
            var childContainer = node.viewChildContainer;
            childContainer.parentRow = element;
            element.signalConnect('dom:mouseenter', function(event) {
                clearTimeout(childContainer.popDownDelay);
                if (!Object.isElement(childContainer.parentNode) || !childContainer.visible())
                    container.childContainers.each(function(c) { popDown.call(this, c) }.bind(this));
                popUp.call(this, childContainer);
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
            var render = this.options.cellAttributes[i] && this.options.cellAttributes[i].renderFunction;
            if (!Object.isFunction(render)) continue;
            render.call(this, element.rows[0].cells[i], this.model.getColumnType(i), values[i]);
        }
    }

    function createNodes(nodes, template, flat) {
        var html = [];
        var container = new Element('div', {className: 'comboview_node_container'});
        container.childContainers = [];
        if (nodes[0] && nodes[0].parentNode) {
            nodes[0].parentNode.viewChildContainer = container;
            container.parentContainer = nodes[0].parentNode.parentNode
                                     && nodes[0].parentNode.parentNode.viewChildContainer
                ? nodes[0].parentNode.parentNode.viewChildContainer
                : this.container;
            container.parentContainer.childContainers.push(container);
        } else {
            this.container = container;
        }
        var index = 0, length = nodes.length;
        nodes.each(function(node) {
            var values = node.getValues();
            var cellTemplate = cellTemplateRenderer.call(this, values);
            if (!flat && node.hasChildren() > 0) {
                cellTemplate.parentalArrow = '<div class="comboview_parental_arrow"></div>';
                createNodes.call(this, node.children(), template);
            }

            if (index == 0)
                cellTemplate.nodePosition = 'comboview_node_first'
            else if (index + 1 == length)
                cellTemplate.nodePosition = 'comboview_node_last'
            cellTemplate.nodePath = node.getPath().toJSON();
            html.push(template.evaluate(cellTemplate));
            ++index;
        }.bind(this));
        container.update(html.join(''));
        var children = container.childElements();
        for (var i = 0, l = nodes.length; i < l; i++) {
            setNodeAttributes.call(this, container, children[i], nodes[i]);
            cellFunctionRenderer.call(this, children[i], nodes[i].getValues());
        }
    }

    function setState(state) {
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

    function setupScrolling(container) {
        var width = container.getStyle('width');
        var height = container.getStyle('height');
        if (this.options.maxHeight > parseFloat(height)) return;
        var scrollbar = document.viewport.getScrollbarSize();
        var new_width = parseInt(width) + scrollbar;
        container.addClassName('scrolling_menu');
        if (Prototype.Browser.Opera)
            container.setStyle({width: new_width + 'px', height: this.options.maxHeight + 'px', overflow: 'auto'});
        else
            container.setStyle({width: new_width + 'px', height: this.options.maxHeight + 'px', overflowY: 'scroll'});
    }


    function popUp(container) {
        var container = Object.isElement(container)
            ? container : this.container;
        if (container.popped) return;
        container.setStyle({display: 'block', visibility: 'hidden'});
        container.popped = true;
        if (!Object.isElement(container.parentNode))
            (container.parentContainer || this).insert({after: container});

        if (!container.positioned) {
            container.select('.comboview_node').each(function(node) {
                node.observe('mouseover', node.addClassName.bind(node, 'comboview_node_highlight'));
                node.observe('mouseout', node.removeClassName.bind(node, 'comboview_node_highlight'));
            });
            if (container.parentRow) {
                var parent_position = container.parentRow.cumulativeOffset();
                parent_position[0] += this.content.down('.comboview_node').getWidth();
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

            var table = container.down();
            container.style.width = table.getWidth()
                + parseFloat(table.getStyle('margin-left') || 0)
                + parseFloat(table.getStyle('margin-right') || 0) + 'px';
            if (this.options.maxHeight)
                setupScrolling.call(this, container);

            container.positioned = true;

            document.observe('click', function(event) {
                var inside = Event.checkElement(event, container);
                if (!inside && !Event.checkElement(event, this))
                    return this.popDown();
                else if (inside) {
                    var path = Event.element(event).up('table.comboview_node').readAttribute('iwl:nodePath').evalJSON();
                    this.setActive(path);
                    return this.popDown();
                }
            }.bind(this));
        }
        container.setStyle({visibility: 'visible'});
    }

    function popDown(container) {
        var container = Object.isElement(container) ? container : this.container;
        container.childContainers.each(function(c) { popDown.call(this, c) }.bind(this));
        if (!container.popped) return;
        container.style.display = 'none';
        container.popped = false;
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
            setState.call(this, (this.state & ~IWL.ComboView.State.SHOW));
        },
        /**
         * Sets the active item of the ComboView
         * @param path The path (or index for flat models) of the item to be set as active
         * @returns The object
         * */
        setActive: function(path) {
            this.selectedPath = path;
            if (!Object.isArray(path)) path = [path];
            var node = this.model.getNodeByPath(path) || this.model.getFirstNode();
            if (!node) return;
            this.values = node.getValues();
            var cellTemplate = cellTemplateRenderer.call(this, this.values);
            setContent.call(this, cellTemplate);

            return this;
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
            this.model = model;
            this.button = this.down('.comboview_button');
            this.content = this.down('.comboview_content');
            this.contentColumns = [];
            if (!this.options.popDownDelay)
                this.options.popDownDelay = 0.3;

            connectSignals.call(this);
            setContent.call(this);

            this.state = 0;
            this.emitSignal('iwl:load');

            if (window.attachEvent)
                window.attachEvent("onunload", function() { this.model = null });

            onDataLoad.call(this, null, this.model.options);
            this.model.signalConnect('iwl:load_data', onDataLoad.bind(this));
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
