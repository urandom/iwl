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

    function setContent(cellTemplate, node) {
        this.content.innerHTML = generateContentTemplate.call(this).evaluate(cellTemplate || {});
        if (node) {
            var values = [], types = [], cMap = this.options.columnMap;
            for (var j = 0, l = cMap.length; j < l; j++) {
                var index = cMap[j];
                values.push(node.values[index]);
                types.push(node.columns[index].type);
            }
            cellFunctionRenderer.call(this, this.content.firstChild.rows[0].cells, values, types, node);
        }

        this.contentWidth = this.content.getWidth();
    }

    function generateContentTemplate() {
        /* Individual rows can't be dragged. Each node has to be a full table */
        var node = ['<table cellpadding="0" cellspacing="0" class="comboview_node"><tbody><tr>'];

        for (var i = 0, l = this.options.columnMap.length; i < l; i++) {
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

        for (var i = 0, l = this.options.columnMap.length; i < l; i++) {
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

    function generateSeparator() {
        var node = ['<table cellpadding="0" cellspacing="0" class="comboview_node_separator"><tbody><tr>'];
        node.push('<td colspan="', this.options.columnMap.length - 1, '"><div style="width: ', this.contentWidth, 'px;"></div></td>');
        node.push('</tr></tbody></table>');
        return node.join('');
    }

    function loadData(event, parentNode) {
        var flat = this.model.isFlat();
        var template = generateNodeTemplate.call(this, flat)
        if (parentNode) {
            var view = parentNode.view[this.id];
            var highlight = view.element.highlight;
            recreateNode.call(this, parentNode, template, flat, view.container);
            if (highlight) {
                changeHighlight.call(this, parentNode);
                popUp.call(this, view.childContainer);
            }
        } else {
            createNodes.call(this, this.model.rootNodes, template, flat);
        }
        this.setActive(this.options.initialPath);
    }

    function eventAbort(event, eventName, params, options) {
        if (eventName == 'IWL-TreeModel-requestChildren') {
            var node = this.model.getNodeByPath(options.parentNode);
            var element = node.view[this.id].element;
            var arrow = element.down('.comboview_partial_loading');
            arrow.removeClassName('comboview_partial_loading').addClassName('comboview_partial_parental_arrow');
            var callback = function(event) {
                element.signalDisconnect('dom:mouseenter', callback);
                if (node.requestChildren())
                    arrow.removeClassName('comboview_partial_parental_arrow').addClassName('comboview_partial_loading');
                else arrow.remove();
            }.bind(this);
            element.signalConnect('dom:mouseenter', callback);
        }
    }

    function cellTemplateRenderer(node) {
        var cellTemplate = {}, values = [], cMap = this.options.columnMap, mappedValues = {};
        for (var i = 0, l = cMap.length; i < l; i++)
            values.push(node.values[cMap[i]]);
        for (var i = 0, l = node.values.length; i < l; i++)
            mappedValues['value' + i] = node.values[i];
        if (this.nodeSeparatorCallback && this.nodeSeparatorCallback(this.model, node))
            return {separator: true};
        for (var i = 0, l = values.length; i < l; i++) {
            var render = this.options.cellAttributes[i].renderTemplate;
            if (render) {
                render = new Template(render);
                var options = Object.isObject(values[i])
                    ? render.evaluate(values[i])
                    : Object.extend(Object.clone(mappedValues), {cellValue: values[i]});
                cellTemplate['column' + i] = render.evaluate(options);
            } else {
                var index = cMap[i];
                var type = this.model.columns[index] ? this.model.columns[index].type : IWL.TreeModel.DataTypes.NONE;
                if (type == IWL.TreeModel.DataTypes.STRING)
                    cellTemplate['column' + i] = values[i].toString();
                else if (type == IWL.TreeModel.DataTypes.INT)
                    cellTemplate['column' + i] = parseInt(values[i])
                else if (type == IWL.TreeModel.DataTypes.FLOAT)
                    cellTemplate['column' + i] = parseFloat(values[i])
                else if (type == IWL.TreeModel.DataTypes.BOOLEAN)
                    cellTemplate['column' + i] = values[i].toString();
                else if (type == IWL.TreeModel.DataTypes.COUNT) {
                    cellTemplate['column' + i] = node.getIndex() + 1 + (this.model.options.offset || 0);
                }
            }
        }
        return cellTemplate;
    }

    function setNodeAttributes(container, element, node) {
        var id = this.id;
        if (!node.view) node.view = {};
        if (!node.view[id]) node.view[id] = {};
        node.view[id].element = element;
        node.view[id].container = container;
        var childContainer = node.view[id].childContainer;
        var hasChildren = node.hasChildren();
        if (element.hasClassName('comboview_node_separator'))
            return;

        element.sensitive = true;
        element.signalConnect('dom:mouseenter', function(event) {
            changeHighlight.call(this, node);
            if (!childContainer || !Object.isElement(childContainer.parentNode) || !childContainer.visible())
                container.childContainers.each(function(c) { popDown.call(this, c) }.bind(this));
        }.bind(this));
        element.signalConnect('dom:mouseleave', function(event) {
            changeHighlight.call(this);
            clearTimeout(container.popUpDelay);
        }.bind(this));

        if (node.attributes.insensitive)
            this.setSensitivity(node, false);

        if (childContainer) {
            childContainer.parentRow = element;
            element.signalConnect('dom:mouseenter', function(event) {
                /* Race condition by incorrect event sequence in IE */
                container.popUpDelay = popUp.bind(this, childContainer).delay(this.options.popUpDelay);
            }.bind(this));
        } else if (null == node.childCount) {
            var callback = function(event) {
                container.popUpDelay = (function() {
                    element.signalDisconnect('dom:mouseenter', callback);
                    var arrow = element.down('.comboview_partial_parental_arrow');
                    if (node.requestChildren())
                        arrow.removeClassName('comboview_partial_parental_arrow').addClassName('comboview_partial_loading');
                    else arrow.remove();
                }).delay(this.options.popUpDelay);
            }.bind(this);
            element.signalConnect('dom:mouseenter', callback);
        }
    }

    function cellFunctionRenderer(cells, values, types, node) {
        for (var i = 0, l = values.length; i < l; i++) {
            var attributes = this.options.cellAttributes[i];
            var render = attributes.renderFunction;
            if (!render) continue;
            render.call(attributes.renderInstance || this, cells[i], values[i], types[i], node);
        }
    }

    function createContainer(parentNode) {
        var container, id = this.id;
        if (parentNode && parentNode.view[id].childContainer)
            container = parentNode.view[id].childContainer
        else {
            if (parentNode) {
                var path = parentNode.getPath();
                var pathString = path.toString();
                container = this.containers[pathString];
                if (!container)
                    container = new Element('div', {
                        className: 'comboview_node_container comboview_node_container_depth' + path.length
                    });
                this.containers[pathString] = container;
                container.path = pathString;

                parentNode.view[id].childContainer = container;
                container.parentContainer = parentNode.parentNode
                                         && parentNode.parentNode.view[id].childContainer
                    ? parentNode.parentNode.view[id].childContainer
                    : this.container;
                container.parentContainer.childContainers.push(container);
                container.childContainers = [];
                container.node = parentNode;
            } else {
                container = this.container;
                if (!container) {
                    container = new Element('div', {className: 'comboview_node_container'});
                    container.registerFocus();
                    container.keyLogger(keyEventsCB.bindAsEventListener(this));
                    container.childContainers = [];
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
        }
        return container;
    }

    function recreateNode(node, template, flat, container) {
        var cellTemplate = cellTemplateRenderer.call(this, node), html, nodePath = node.getPath().toJSON(), id = this.id;
        if (cellTemplate.separator) {
            html = generateSeparator.call(this);
        } else {
            var childCount = node.childCount;
            if (!flat && (childCount != 0)) {
                var className = childCount ? 'comboview_parental_arrow' : 'comboview_partial_parental_arrow';
                cellTemplate.parentalArrow = ['<div class="', className, '"></div>'].join('');
                if (childCount)
                    createNodes.call(this, node.childNodes, template);
            }

            if (!node.previousSibling && !node.nextSibling)
                cellTemplate.nodePosition = 'comboview_node_first comboview_node_last'
            else if (!node.previousSibling)
                cellTemplate.nodePosition = 'comboview_node_first'
            else if (!node.nextSibling)
                cellTemplate.nodePosition = 'comboview_node_last'
            cellTemplate.nodePath = nodePath;
            html = template.evaluate(cellTemplate);
        }
        var next = node.nextSibling;
        if (Object.isElement(node.view[id].element) && node.view[id].element.parentNode)
            node.view[id].element.replace(html);
        else {
            if (next)
                next.view[id].element.insert({before: html});
            else if (node.previousSibling)
                node.previousSibling.view[id].element.insert({after: html});
            else
                container.innerHTML = html;
        }
        var element = next ? next.view[id].element.previousSibling : container.lastChild;
        var values = [], types = [], cMap = this.options.columnMap;
        for (var j = 0, l = cMap.length; j < l; j++) {
            var index = cMap[j];
            values.push(node.values[index]);
            types.push(node.columns[index].type);
        }
        setNodeAttributes.call(this, container, element, node);
        cellFunctionRenderer.call(this, element.rows[0].cells, values, types, node);
    }

    function createNodes(nodes, template, flat) {
        var html = [], container, nodeLength = nodes.length;
        var container = createContainer.call(this, nodes[0] ? nodes[0].parentNode : null);
        for (var i = 0, node = nodes[0]; i < nodeLength; node = nodes[++i]) {
            var cellTemplate = cellTemplateRenderer.call(this, node);
            if (cellTemplate.separator) {
                html.push(generateSeparator.call(this));
                continue;
            }
            var childCount = node.childCount;
            if (!flat && (childCount != 0)) {
                var className = childCount ? 'comboview_parental_arrow' : 'comboview_partial_parental_arrow';
                cellTemplate.parentalArrow = ['<div class="', className, '"></div>'].join('');
                if (childCount)
                    createNodes.call(this, node.childNodes, template);
            }

            if (i + 1 == nodeLength && i == 0)
                cellTemplate.nodePosition = 'comboview_node_first comboview_node_last'
            else if (i == 0)
                cellTemplate.nodePosition = 'comboview_node_first'
            else if (i + 1 == nodeLength)
                cellTemplate.nodePosition = 'comboview_node_last'
            cellTemplate.nodePath = node.getPath().toJSON();
            html.push(template.evaluate(cellTemplate));
        };
        container.innerHTML = html.join('');
        var children = container.childElements();
        for (var i = 0; i < nodeLength; i++) {
            var values = [], types = [], cMap = this.options.columnMap, node = nodes[i];
            for (var j = 0, l = cMap.length; j < l; j++) {
                var index = cMap[j];
                values.push(node.values[index]);
                types.push(node.columns[index].type);
            }
            setNodeAttributes.call(this, container, children[i], node);
            cellFunctionRenderer.call(this, children[i].rows[0].cells, values, types, node);
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
        clearTimeout(container.popDownDelay);
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
            if (!table) return;
            inner.style.width = table.getWidth()
                + parseFloat(table.getStyle('margin-left') || 0)
                + parseFloat(table.getStyle('margin-right') || 0) + 'px';

            if (this.options.maxHeight)
                setupScrolling.call(this, inner, this.container.pageContainer);

            container.initialized = true;

            container.observe('click', function(event) {
                if (!Event.isLeftClick(event)) return;
                var element = Event.element(event).up('.comboview_node');
                if (!element || element.descendantOf(this)) return;
                var path = element.readAttribute('iwl:nodePath').evalJSON();
                if (this.setActive(path))
                    return this.popDown();
                else Event.stop(event);
            }.bind(this));
        }
        container.setStyle({visibility: 'visible'});
    }

    function popDown(container) {
        var container = Object.isElement(container)
            ? container
            : this.container.pageContainer || this.container;
        if (!container || !container.popped) return;
        (container == this.container.pageContainer ? this.container : container).childContainers.each(
            function(c) { popDown.call(this, c) }.bind(this)
        );
        if (!container.popped) return;
        container.style.display = 'none';
        container.popped = false;
    }

    function changeHighlight(node) {
        var current = this.currentNodeHighlight, id = this.id;
        if (current) {
            current.view[id].element.removeClassName('comboview_node_highlight');
            current.view[id].element.highlight = false;
        }
        if (node) {
            if (node.view[id].element.sensitive || node.childCount != 0)
                node.view[id].element.addClassName('comboview_node_highlight');
            node.view[id].element.highlight = true;
        }
        this.currentNodeHighlight = node;
    }

    function keyEventsCB(event) {
        var current = this.currentNodeHighlight, id = this.id;
        var row = current ? current.view[id].element : null;
        if (!row || !row.highlight)
            return;
        var keyCode = Event.getKeyCode(event);
        var row;
        if (![Event.KEY_UP, Event.KEY_DOWN, Event.KEY_RETURN].include(keyCode)) return;
        var nodes = this.model.toArray(), node;

        if (keyCode == Event.KEY_UP)  {
            var index = nodes[nodes.indexOf(current)];
            while (node = nodes[--index]) {
                if (!node || node.view[id].element.hasClassName('comboview_node_separator'))
                    continue;
                else break;
            }
            changeHighlight.call(this, node);
            Event.stop(event);
        } else if (keyCode == Event.KEY_DOWN) {
            var index = nodes[nodes.indexOf(current)];
            while (node = nodes[++index]) {
                if (!node || node.view[id].element.hasClassName('comboview_node_separator'))
                    continue;
                else break;
            }
            changeHighlight.call(this, node);
            Event.stop(event);
        } else if (keyCode == Event.KEY_RETURN) {
            if (current.view[id].element.hasClassName('comboview_node_separator')) return;
            this.setActive(current);
            this.popDown();
        }
    }

    function normalizeCellAttributes() {
        for (var i = 0, l = this.options.columnMap.length; i < l; i++) {
            var cAttrs = this.options.cellAttributes[i];
            if (!cAttrs) {
                this.options.cellAttributes[i] = {};
                continue;
            }
            var renderClass = cAttrs.renderClass;
            var renderFunction = cAttrs.renderFunction;
            cAttrs.renderClass = cAttrs.renderFunction = undefined;
            if (renderClass) {
                var klass = renderClass.name.objectize();
                if (Object.isFunction(klass)) {
                    var instance = new klass(renderClass.options);
                    if (Object.isFunction(instance.render)) {
                        cAttrs.renderFunction = instance.render;
                        cAttrs.renderInstance = instance;
                    }
                }
            } else if (renderFunction) {
                cAttrs.renderFunction = Object.isString(renderFunction)
                    ? renderFunction.objectize()
                    : Object.isFunction(renderFunction)
                        ? renderFunction
                        : undefined;
            }
        }
    }

    function pageChanging() {
        this.pageChanging = true;
        IWL.View.disable({element: this.container.pageContainer});
    }

    function pageChange() {
        IWL.View.enable();
        this.pageChanging = undefined;
        if (this.popDownRequest) {
            this.popDownRequest = undefined;
            this.popDown();
        }
    }

    function nodesSwap(event, node1, node2) {
        var id = this.id;
        var c1 = node1.view[id].container, c2 = node2.view[id].container;
        node1.view[id].container = c2, node2.view[id].container = c1;

        var childContainer = node1.view[id].childContainer;
        node1.view[id].element.remove();
        if (childContainer)
            removeContainers.call(this, childContainer);
        nodeChange.call(this, event, node1);

        childContainer = node2.view[id].childContainer;
        node2.view[id].element.remove();
        if (childContainer)
            removeContainers.call(this, childContainer);
        nodeChange.call(this, event, node2);
    }

    function nodeMove(event, node, parentNode, previousParent) {
        var view = node.view[this.id];
        if (view.element && view.element.parentNode == previousParent)
            view.element.remove();

        nodeInsert.call(this, event, node, parentNode);
    }

    function nodeChange(event, node) {
        var flat = this.model.isFlat(), view = node.view[this.id];
        var template = generateNodeTemplate.call(this, flat)
        var highlight = view.element.highlight;
        recreateNode.call(this, node, template, flat, view.container);
        if (highlight) {
            changeHighlight.call(this, node);
            popUp.call(this, view.childContainer);
        }
    }

    function nodeInsert(event, node, parentNode) {
        var flat = this.model.isFlat();
        var template = generateNodeTemplate.call(this, flat)
        var id = this.id;
        if (!node.view) node.view = {};
        if (!node.view[id]) node.view[id] = {};
        var container = parentNode ? createContainer.call(this, parentNode) : this.container;
        recreateNode.call(this, parentNode || node, template, flat, container);
        generatePathAttributes.call(this, parentNode);
    }

    function nodeRemove(event, node, parentNode) {
        var view = node.view[this.id];
        var element = view.element;
        var container = view.container;
        var childContainer = view.childContainer;
        var styleHeight = parseFloat(container.style.height);
        var height = container.getHeight();

        if (height >= container.scrollHeight)
            container.style.height = styleHeight - element.getHeight() + 'px';


        if (childContainer)
            removeContainers.call(this, childContainer);
        element.remove();

        var count = parentNode ? parentNode.childCount : this.model.rootNodes.length;
        if (count)
            generatePathAttributes.call(this, parentNode);
        else {
            removeContainers.call(this, container);
            var flat = this.model.isFlat();
            var template = generateNodeTemplate.call(this, flat)
            var container = parentNode ? createContainer.call(this, parentNode) : this.container;
            recreateNode.call(this, parentNode || node, template, flat, container);
        }
    }
    
    function removeContainers(container) {
        var id = this.id;
        if (container.parentNode)
            container.remove();
        delete this.containers[container.path];
        if (container.node && container.node.view[id].childContainer)
            delete container.node.view[id].childContainer;
        for (var i = 0, l = container.childContainers.length; i < l; i++)
            removeContainers.call(this, container.childContainers[i]);
        container.childContainers = [];
    }

    function generatePathAttributes(parentNode) {
        var childNodes, parentPath;
        if (parentNode) {
            childNodes = parentNode.childNodes;
            parentPath = parentNode.getPath();
        } else {
            childNodes = this.model.rootNodes;
            parentPath = [];
        }
        for (var i = 0, l = childNodes.length; i < l; i++) {
            var child = childNodes[i];
            var path = parentPath.concat(i);
            var element = child.view[this.id].element;
            element.writeAttribute('iwl:nodePath', Object.toJSON(path));
            if (child.childNodes.length)
                generatePathAttributes.call(this, child);
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
            if (!node || !node.view[this.id].element.sensitive) return;
            this.content.removeClassName('comboview_content_empty');
            this.values = node.getValues();
            var cellTemplate = cellTemplateRenderer.call(this, node);
            setContent.call(this, cellTemplate, node);

            return this.emitSignal('iwl:change', this.values);
        },
        /**
         * @returns The active item of the ComboView
         * */
        getActive: function() {
            return this.selectedPath;
        },
        /**
         * Sets the sentisitivy of the item
         * @param path The path (or index for flat models) of the item to be set as active
         * @param {Boolean} sensitive If false, the item will be insensitive
         * @returns The object
         * */
        setSensitivity: function(path, sensitive) {
            var node;
            if (path instanceof IWL.TreeModel.Node) {
                node = path;
            } else {
                if (!Object.isArray(path)) path = [path];
                node = this.model.getNodeByPath(path) || this.model.getFirstNode();
            }
            if (!node) return;
            var element = node.view[this.id].element;
            if (!element) return;
            var hasChildren = node.childCount != 0;
            element[sensitive ? 'removeClassName' : 'addClassName'](hasChildren ? 'comboview_partial_node_insensitive' : 'comboview_node_insensitive');
            element.sensitive = !!sensitive;

            return this.emitSignal('iwl:sensitivity_change', node);
        },

        _init: function(id, model) {
            this.options = Object.extend({
                columnWidth: [],
                columnClass: [],
                cellAttributes: [],
                initialPath: [0],
                maxHeight: 400,
                popUpDelay: 0.2
            }, arguments[2]);
            if (Object.keys(model.options.columnTypes).length)
                IWL.TreeModel.overrideDefaultDataTypes(model.options.columnTypes);
            this.model = new IWL.TreeModel(model);
            this.button = this.down('.comboview_button');
            this.content = this.down('.comboview_content');
            this.contentColumns = [];
            this.containers = {};
            if (this.options.pageControl) {
                this.pageControl = $(this.options.pageControl);
                this.pageControl.signalConnect('iwl:current_page_is_changing', pageChanging.bind(this));
                this.pageControl.signalConnect('iwl:current_page_change', pageChange.bind(this));
            }
            if (this.pageControl && this.options.pageControlEventName)
                this.pageControl.bindToWidget($(this.model.options.id), this.options.pageControlEventName);

            connectSignals.call(this);
            setContent.call(this);

            this.state = 0;
            this.emitSignal('iwl:load');

            if (window.attachEvent)
                window.attachEvent("onunload", function() { this.model = null });

            this.nodeSeparatorCallback = Object.isString(this.options.nodeSeparatorCallback)
                ? this.options.nodeSeparatorCallback.objectize()
                : Object.isFunction(this.options.nodeSeparatorCallback)
                    ? this.options.nodeSeparatorCallback : null;

            normalizeCellAttributes.call(this);
            loadData.call(this, null);
            var callback = loadData.bind(this);
            this.model.signalConnect('iwl:event_abort', eventAbort.bind(this));
            this.model.signalConnect('iwl:load_data', callback);
            this.model.signalConnect('iwl:sort_column_change', callback);
            this.model.signalConnect('iwl:nodes_reorder', callback);
            this.model.signalConnect('iwl:nodes_swap',  nodesSwap.bind(this));
            this.model.signalConnect('iwl:node_move',   nodeMove.bind(this));
            this.model.signalConnect('iwl:node_change', nodeChange.bind(this));
            this.model.signalConnect('iwl:node_insert', nodeInsert.bind(this));
            this.model.signalConnect('iwl:node_remove', nodeRemove.bind(this));

            document.observe('click', function(event) {
                if (!Event.isLeftClick(event)) return;
                var containers = [this.container].concat(Object.values(this.containers));
                for (var i = 0, l = containers.length; i < l; i++) {
                    if (Event.checkElement(event, containers[i]))
                        return;
                }
                if (!Event.checkElement(event, this))
                    return this.popDown();
            }.bind(this));

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
