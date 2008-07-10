// vim: set autoindent shiftwidth=4 tabstop=8:
IWL.TreeView = Object.extend(Object.extend({}, IWL.Widget), (function () {
    var nodeMap = {},
        nodeIndent = '<div class="treeview_node_indent"></div>',
        nodeStraightLine = '<div class="treeview_node_indent treeview_node_straight_line"></div>',
        nodeOnlyParent = '<div class="treeview_node_indent treeview_node_parent treeview_node_single_parent"></div>',
        nodeOnlyPartial = '<div class="treeview_node_indent treeview_node_parent treeview_node_single_partial"></div>',
        nodeOnlyLine = '<div class="treeview_node_indent treeview_node_single_line"></div>',
        nodeTopParent = '<div class="treeview_node_indent treeview_node_parent treeview_node_top_parent"></div>',
        nodeTopPartial = '<div class="treeview_node_indent treeview_node_parent treeview_node_top_partial"></div>',
        nodeTopLine = '<div class="treeview_node_indent treeview_node_top_line"></div>',
        nodeBottomParent = '<div class="treeview_node_indent treeview_node_parent treeview_node_bottom_parent"></div>',
        nodeBottomPartial = '<div class="treeview_node_indent treeview_node_parent treeview_node_bottom_partial"></div>',
        nodeBottomLine = '<div class="treeview_node_indent treeview_node_bottom_line"></div>',
        nodeParent = '<div class="treeview_node_indent treeview_node_parent treeview_node_normal_parent"></div>',
        nodePartial = '<div class="treeview_node_indent treeview_node_parent treeview_node_normal_partial"></div>',
        nodeLine = '<div class="treeview_node_indent treeview_node_line"></div>',
        indentFragment = /^(.*)<div[^>]+><\/div>$/,
        dragMultipleNodes = new Template('<span class="treeview_dragged_nodes">#{text}</span>'),
        hoverOverlapState = {
            NONE:   0,
            TOP:    1,
            BOTTOM: 2,
            CENTER: 3
        };

    function connectSignals() {
        Event.delegate(this, 'click', '.treeview_node_parent', function(event) {
            var element = Event.element(event);
            if (!Element.hasClassName(element, 'treeview_node'))
                element = Element.up(element, '.treeview_node');
            if (!element || Element.hasClassName(element, 'treeview_node_loading')) return;
            if (Element.hasClassName(element, 'treeview_node_expanded'))
                this.collapseNode(element.node);
            else
                this.expandNode(element.node, event.shiftKey);
        }.bind(this));
    }

    function generateNodeTemplate() {
        /* Individual rows can't be dragged. Each node has to be a full table */
        var node = ['<table cellpadding="0" cellspacing="0" class="iwl-node treeview_node #{nodePosition}"><tbody><tr>'];

        for (var i = 0, l = this.options.columnMap.length; i < l; i++) {
            var classNames = ['treeview_column', 'treeview_column' + i], width = '';
            if (this.options.columnClass[i])
                classNames.push(this.options.columnClass[i]);
            if (i == 0) classNames.push('treeview_column_first');
            if (i == l - 1) classNames.push('treeview_column_last');
            if (this.options.columnWidth[i])
                width = ' style="width: ' + this.options.columnWidth[i] + 'px;"';
            node.push('<td class="', classNames.join(' '), '"', width, '>', (i == 0 && !this.flat ? '#{indent}' : ''), '#{column', i, '}</td>');
        }
        node.push('</tr></tbody></table>');

        return new Template(node.join(''));
    }

    function generateSeparator() {
        var node = ['<table cellpadding="0" cellspacing="0" class="treeview_node_separator"><tbody><tr>'];
        node.push('<td colspan="', this.options.columnMap.length - 1, '"><div style="width: ', this.container.clientWidth, 'px;"></div></td>');
        node.push('</tr></tbody></table>');
        return node.join('');
    }

    function headerTemplateRenderer() {
        var headerTemplate = {}, cMap = this.options.columnMap;
        for (var i = 0, l = cMap.length; i < l; i++) {
            var header = this.options.cellAttributes[i].header;
            var template = header.template || this.options.cellAttributes[i].templateRenderer.header;
            if (!(template instanceof Template))
                template = new Template(template);
            var options = {title: header.title, modelColumnIndex: cMap[i]};
            headerTemplate['column' + i] = template.evaluate(options);
        }
        return headerTemplate;
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
                var options = Object.extend(Object.clone(mappedValues), {cellValue: values[i]});
                cellTemplate['column' + i] = render.evaluate(options);
            } else {
                var template = this.options.cellAttributes[i].templateRenderer;
                if (template)
                    cellTemplate['column' + i] = template.render(values[i], node, cMap[i]);
            }
        }
        return cellTemplate;
    }

    function setNodeAttributes(container, element, node, indent) {
        var id = this.id, nId = node.attributes.id, map = nodeMap[id];
        if (!map[nId]) map[nId] = {};
        var nView = map[nId];
        nView.node = node, nView.element = element, nView.container = container, nView.indent = indent;
        element.node = node;
        if (nView.childContainer && !nView.childContainer.parentNode) {
            var next = element.nextSibling;
            next
                ? element.parentNode.insertBefore(nView.childContainer, next)
                : element.parentNode.appendChild(nView.childContainer);
        }
        if (nView.expanded)
            Element.addClassName(element, 'treeview_node_expanded');
        if (this.options.dragDest && !element.__droppableInit)
            setDroppableNode.call(this, node, nView, map);
        if (Element.hasClassName(element, 'treeview_node_separator'))
            return;

        element.sensitive = true;
        Element.signalConnect(element, 'dom:mouseenter', function(event) {
            if ((this.boxSelection && this.boxSelection.dragging) || (this.content.iwl && this.content.iwl.draggable && this.content.iwl.draggable.dragging) || !element.sensitive) return;
            changeHighlight.call(this, node);
        }.bind(this));
        Element.signalConnect(element, 'dom:mouseleave', function(event) {
            if ((this.boxSelection && this.boxSelection.dragging) || (this.content.iwl && this.content.iwl.draggable && this.content.iwl.draggable.dragging) || !element.sensitive) return;
            changeHighlight.call(this);
        }.bind(this));

        if (node.attributes.insensitive)
            this.setSensitivity(node, false);

        Element.signalConnect(element, 'mousedown', eventNodeMouseDown.bindAsEventListener(this, node));
        Element.signalConnect(element, 'mouseup', eventNodeMouseUp.bindAsEventListener(this, node));
    }

    function cellFunctionRenderer(cells, values, node) {
        for (var i = 0, l = values.length; i < l; i++) {
            var attributes = this.options.cellAttributes[i];
            var render = attributes.renderFunction;
            if (!render) continue;
            render.call(attributes.renderInstance || this, cells[i], values[i], node);
        }
    }

    function createContainer(parentNode) {
        var container, id = this.id;
        if (parentNode) {
            var nId = parentNode.attributes.id;
            if (!nodeMap[id][nId])
                nodeMap[id][nId] = {};
            if (nodeMap[id][nId].childContainer)
                return nodeMap[id][nId].childContainer
        }
        if (parentNode) {
            var path = parentNode.getPath();
            var pathString = path.toString();
            container = this.containers[pathString];
            if (!container)
                container = new Element('div', {
                    className: 'treeview_node_container treeview_node_container_depth' + path.length,
                    style: 'display: none'
                });
            this.containers[pathString] = container;
            container.path = pathString;

            nodeMap[id][nId].childContainer = container;
            var parentContainer = parentNode.parentNode
                                     && nodeMap[id][parentNode.parentNode.attributes.id].childContainer
                ? nodeMap[id][parentNode.parentNode.attributes.id].childContainer
                : this.container;
            parentContainer.childContainers.push(container);
            container.childContainers = [];
            container.node = parentNode;
        } else {
            container = this.container;
            if (!container) {
                container = new Element('div', {className: 'treeview_content treeview_node_container'});
                container.childContainers = [];
            }
            if (this.pageControl && !container.pageContainer && !this.options.placedPageControl) {
                var pageContainer = new Element('div', {className: 'treeview_page_container'});
                pageContainer.appendChild(container);
                pageContainer.appendChild(this.pageControl);
                this.pageControl.setStyle({position: '', left: ''});
                container.pageContainer = pageContainer;
            }
            this.container = container;
        }
        return container;
    }

    function createHeader() {
        var template = generateNodeTemplate.call(this), html, id = this.id,
            headerTemplate = headerTemplateRenderer.call(this);
        headerTemplate.nodePosition = 'treeview_header_node';
        if (!this.flat)
            headerTemplate.indent = nodeIndent;
        html = template.evaluate(headerTemplate);
        this.header.innerHTML = html;
    }

    function recreateNode(node, template, container, indent) {
        var cellTemplate = cellTemplateRenderer.call(this, node), html, id = this.id, parentNode = node.parentNode;
        if (cellTemplate.separator) {
            html = generateSeparator.call(this);
        } else {
            if (!this.flat && !indent)
                indent = '';
            var childCount = node.childCount, newIndent;
            if (!this.flat && indent)
                indent = indent.replace(indentFragment, "$1");
            if (!node.previousSibling && !node.nextSibling) {
                cellTemplate.nodePosition = 'treeview_node_first treeview_node_last'
                if (!this.flat && this.options.drawExpanders) {
                    cellTemplate.indent = indent + (childCount != 0 
                        ? childCount 
                            ? parentNode ? nodeBottomParent : nodeOnlyParent
                            : parentNode ? nodeBottomPartial : nodeOnlyPartial
                        : parentNode ? nodeBottomLine : nodeLine);
                    newIndent = indent + nodeIndent;
                }
            } else if (!node.previousSibling) {
                cellTemplate.nodePosition = 'treeview_node_first'
                if (!this.flat && this.options.drawExpanders) {
                    cellTemplate.indent = indent + (childCount != 0 
                        ? childCount
                            ? parentNode ? nodeParent : nodeTopParent
                            : parentNode ? nodePartial : nodeTopPartial
                        : parentNode ? nodeLine : nodeTopLine);
                    newIndent = indent + nodeStraightLine;
                }
            } else if (!node.nextSibling) {
                cellTemplate.nodePosition = 'treeview_node_last'
                if (!this.flat && this.options.drawExpanders) {
                    cellTemplate.indent = indent + (childCount != 0 
                        ? childCount ? nodeBottomParent : nodeBottomPartial
                        : nodeBottomLine);
                    newIndent = indent + nodeIndent;
                }
            } else if (!this.flat && this.options.drawExpanders) {
                cellTemplate.indent = indent + (childCount != 0 
                    ? childCount ? nodeParent : nodePartial
                    : nodeLine);
                newIndent = indent + nodeStraightLine;
            }
            html = template.evaluate(cellTemplate);
        }
        var next = node.nextSibling, previous = node.previousSibling,
            map = nodeMap[id], element = nodeMap[id][node.attributes.id].element;
        if (Object.isElement(element) && element.parentNode)
            element.replace(html);
        else {
            if (next)
                map[next.attributes.id].element.insert({before: html});
            else if (previous)
                map[previous.attributes.id].element.insert({after: html});
            else
                container.innerHTML = html;
        }
        element = next ? map[next.attributes.id].element.previous('.iwl-node') : container.lastChild;
        if (Element.hasClassName(element.next(), 'treeview_node_container'))
            createNodes.call(this, node.childNodes, template, newIndent);
        var values = [], cMap = this.options.columnMap;
        for (var j = 0, l = cMap.length; j < l; j++) {
            var index = cMap[j];
            values.push(node.values[index]);
        }
        setNodeAttributes.call(this, container, element, node, newIndent);
        cellFunctionRenderer.call(this, element.rows[0].cells, values, node);
    }

    function createNodes(nodes, template, indent) {
        var html = [], container, indents = {}, nodeLength = nodes.length, parentNode = nodes[0] ? nodes[0].parentNode : null;
        var container = createContainer.call(this, parentNode);
        if (!this.flat && !indent)
            indent = '';
        for (var i = 0, node = nodes[0]; i < nodeLength; node = nodes[++i]) {
            var cellTemplate = cellTemplateRenderer.call(this, node);
            if (cellTemplate.separator) {
                html.push(generateSeparator.call(this));
                continue;
            }

            var childCount = node.childCount;
            if (i + 1 == nodeLength && i == 0) {
                cellTemplate.nodePosition = 'treeview_node_first treeview_node_last'
                if (!this.flat && this.options.drawExpanders) {
                    cellTemplate.indent = indent + (childCount != 0 
                        ? childCount 
                            ? parentNode ? nodeBottomParent : nodeOnlyParent
                            : parentNode ? nodeBottomPartial : nodeOnlyPartial
                        : parentNode ? nodeBottomLine : nodeLine);
                    indents[node.attributes.id] = indent + nodeIndent;
                }
            } else if (i == 0) {
                cellTemplate.nodePosition = 'treeview_node_first'
                if (!this.flat && this.options.drawExpanders) {
                    cellTemplate.indent = indent + (childCount != 0 
                        ? childCount
                            ? parentNode ? nodeParent : nodeTopParent
                            : parentNode ? nodePartial : nodeTopPartial
                        : parentNode ? nodeLine : nodeTopLine);
                    indents[node.attributes.id] = indent + nodeStraightLine;
                }
            } else if (i + 1 == nodeLength) {
                cellTemplate.nodePosition = 'treeview_node_last'
                if (!this.flat && this.options.drawExpanders) {
                    cellTemplate.indent = indent + (childCount != 0 
                        ? childCount ? nodeBottomParent : nodeBottomPartial
                        : nodeBottomLine);
                    indents[node.attributes.id] = indent + nodeIndent;
                }
            } else if (!this.flat && this.options.drawExpanders) {
                cellTemplate.indent = indent + (childCount != 0 
                    ? childCount ? nodeParent : nodePartial
                    : nodeLine);
                indents[node.attributes.id] = indent + nodeStraightLine;
            }
            html.push(template.evaluate(cellTemplate));
        };
        container.innerHTML = html.join('');
        var children = container.childNodes;
        setTimeout(function() {
            for (var i = 0, j = 0, l = children.length; i < l; i++) {
                var element = children[i];
                if (element.nodeType != 1 || !Element.hasClassName(element, 'iwl-node'))
                    continue;
                var values = [], cMap = this.options.columnMap, node = nodes[j++];
                for (var k = 0, m = cMap.length; k < m; k++) {
                    var index = cMap[k];
                    values.push(node.values[index]);
                }
                setNodeAttributes.call(this, container, element, node, indents[node.attributes.id]);
                cellFunctionRenderer.call(this, element.rows[0].cells, values, node);
            }
        }.bind(this), 1);
    }

    function changeHighlight(node) {
        var current = this.currentNodeHighlight;
        if (current) {
            var element = nodeMap[this.id][current.attributes.id].element;
            element.removeClassName('treeview_node_highlight');
            element.highlight = false;
        }
        if (node) {
            var element = nodeMap[this.id][node.attributes.id].element;
            if (element.sensitive || node.childCount != 0)
                element.addClassName('treeview_node_highlight');
            element.highlight = true;
        }
        this.currentNodeHighlight = node;
    }

    function normalizeCellAttributes() {
        for (var i = 0, l = this.options.columnMap.length; i < l; i++) {
            var cAttrs = this.options.cellAttributes[i];
            if (!cAttrs)
                cAttrs = this.options.cellAttributes[i] = {};
            var renderClass = cAttrs.renderClass;
            var renderFunction = cAttrs.renderFunction;
            cAttrs.renderClass = cAttrs.renderFunction = undefined;
            if (renderClass) {
                if (cAttrs.renderInstance)
                    continue;
                var klass = renderClass.name.objectize();
                if (klass instanceof IWL.CellRenderer) {
                    var instance = new klass(renderClass.options);
                    if (Object.isFunction(instance.render)) {
                        cAttrs.renderFunction = instance.render;
                        cAttrs.renderInstance = instance;
                    }
                }
            } else if (renderFunction) {
                if (Object.isFunction(renderFunction))
                    continue;
                cAttrs.renderFunction = Object.isString(renderFunction)
                    ? renderFunction.objectize()
                    : undefined;
            } else {
                var type = this.model.columns[this.options.columnMap[i]].type,
                    options = {view: this, editable: cAttrs.editable};
                switch(type) {
                    case IWL.ListModel.DataType.STRING:
                        cAttrs.templateRenderer = new IWL.CellTemplateRenderer.String(options);
                        break;
                    case IWL.ListModel.DataType.INT:
                        cAttrs.templateRenderer = new IWL.CellTemplateRenderer.Int(options);
                        break;
                    case IWL.ListModel.DataType.FLOAT:
                        cAttrs.templateRenderer = new IWL.CellTemplateRenderer.Float(options);
                        break;
                    case IWL.ListModel.DataType.BOOLEAN:
                        cAttrs.templateRenderer = new IWL.CellTemplateRenderer.Boolean(options);
                        break;
                    case IWL.ListModel.DataType.COUNT:
                        cAttrs.templateRenderer = new IWL.CellTemplateRenderer.Count(options);
                        break;
                    case IWL.ListModel.DataType.IMAGE:
                        cAttrs.templateRenderer = new IWL.CellTemplateRenderer.Image(options);
                        break;
                }
            }
            if (!cAttrs.header) cAttrs.header = {};
        }
    }

    function pageChanging() {
        this.pageChanging = true;
        var container = this.container.pageContainer || this.container;
        IWL.View.disable({element: container && container.visible() ? container: null});
    }

    function pageChange() {
        IWL.View.enable();
        this.pageChanging = undefined;
        if (this.popDownRequest) {
            this.popDownRequest = undefined;
        }
    }

    function requestChildren(event, parentNode, options) {
        if (!parentNode) return;
        var view = nodeMap[this.id][parentNode.attributes.id];
        var highlight = view.element.highlight;
        recreateNode.call(this, parentNode, generateNodeTemplate.call(this), view.container, view.indent);
        Element.removeClassName(view.element, 'treeview_node_loading');
        this.expandNode(parentNode, options.allDescendants);
        if (highlight)
            changeHighlight.call(this, parentNode);
    }

    function loadData(event, parentNode) {
        var template = generateNodeTemplate.call(this);
        if (parentNode) {
            var view = nodeMap[this.id][parentNode.attributes.id];
            var highlight = view.element.highlight;
            recreateNode.call(this, parentNode, template, view.container, view.indent);
            if (highlight)
                changeHighlight.call(this, parentNode);
        } else {
            createNodes.call(this, this.model.rootNodes, template);
        }
    }

    function eventAbort(event, eventName, params, options) {
        if (eventName == 'IWL-TreeModel-requestChildren') {
            var node = this.model.getNodeByPath(options.parentNode);
            var element = nodeMap[this.id][node.attributes.id].element;
            Element.removeClassName(element, 'treeview_node_loading');
        }
    }

    function nodesSwap(event, node1, node2) {
        var n1View = nodeMap[this.id][node1.attributes.id],
            n2View = nodeMap[this.id][node2.attributes.id];
        var c1 = n1View.container, c2 = n2View.container;
        n1View.container = c2, n2View.container = c1;

        var childContainer = n1View.childContainer;
        n1View.element.remove();
        if (childContainer)
            removeContainers.call(this, childContainer);
        nodeChange.call(this, event, node1);

        childContainer = n2View.childContainer;
        n2View.element.remove();
        if (childContainer)
            removeContainers.call(this, childContainer);
        nodeChange.call(this, event, node2);
    }

    function nodeMove(event, node, parentNode, previousParent) {
        var view = nodeMap[this.id][node.attributes.id];
        if (view.element && view.element.parentNode)
            view.element.remove();

        nodeInsert.call(this, event, node, parentNode);
    }

    function nodeChange(event, node, columns) {
        var view = nodeMap[this.id][node.attributes.id], cMap = this.options.columnMap, change = false;
        if (columns) {
            for (var i = 0, l = columns.length; i < l; i++) {
                var index = cMap.indexOf(columns[i]);
                if (index == -1) continue;
                var value = node.values[columns[i]];
                switch (this.model.columns[columns[i]].type) {
                    case IWL.ListModel.DataType.BOOLEAN:
                        var input = view.element.down('.treeview_column' + index + ' input');
                        if (value == input.checked) continue;
                        break;
                    default:
                        var text = Element.getText(view.element);
                        if (value == text) continue;
                        break;
                }
                change = true;
                break;
            }
        } else change = true;
        if (!change) return;
        var template = generateNodeTemplate.call(this)
        var highlight = view.element.highlight;
        recreateNode.call(this, node, template, view.container, view.indent);
        if (highlight) {
            changeHighlight.call(this, node);
        }
    }

    function nodeInsert(event, node, parentNode) {
        var template = generateNodeTemplate.call(this), map = nodeMap[this.id];
        var nId = node.attributes.id;
        var container = parentNode ? createContainer.call(this, parentNode) : this.container;
        var indent = parentNode ? map[parentNode.attributes.id].indent : '';
        if (!map[nId]) map[nId] = {};
        if (!node.nextSibling && node.previousSibling)
            map[node.previousSibling.attributes.id].element.removeClassName('treeview_node_last');
        recreateNode.call(this, parentNode || node, template, container, indent);
        if ((parentNode && parentNode.childCount == 1) || this.model.rootNodes.length == 1)
            createNodes.call(this, [node], generateNodeTemplate.call(this), indent);
    }

    function nodeRemove(event, node, parentNode) {
        var view = nodeMap[this.id][node.attributes.id];
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
        if (!count) {
            removeContainers.call(this, container);
            var template = generateNodeTemplate.call(this)
            var container = parentNode ? createContainer.call(this, parentNode) : this.container;
            recreateNode.call(this, parentNode || node, template, container, parentNode ? nodeMap[id][parentNode.attributes.id].indent : '');
        }
    }
    
    function removeContainers(container) {
        if (container.parentNode)
            container.remove();
        delete this.containers[container.path];
        if (container.node) {
            var view = nodeMap[this.id][container.node.attributes.id];
            if (view.childContainer)
                delete view.childContainer;
        }
        for (var i = 0, l = container.childContainers.length; i < l; i++)
            removeContainers.call(this, container.childContainers[i]);
        container.childContainers = [];
    }

    function removeModel() {
        removeContainers.call(this, this.container);
        nodeMap[this.id] = {};
        this.model = this.container = undefined;
    }

    function setPager() {
        this.pageControl.unbind();
        this.pageControl.bindToWidget($(this.model.options.id), this.options.pageControlEventName);
    }

    function eventMouseDown(event) {
        var map = nodeMap[this.id];
        if (map.nodeSelected) {
            delete map.nodeSelected;
            return;
        }
        if (map.skipNodeSelect)
            return;
        if (map.expandNode) {
            delete map.expandNode;
            return;
        }
        if (event.ctrlKey || event.shiftKey)
            return;

        var pointer = [Event.pointerX(event), Event.pointerY(event)];
        var pos     = Element.cumulativeOffset(this);
        pointer = [pointer[0] - pos[0], pointer[1] - pos[1]];
        if (   this.clientWidth < pointer[0]
            || this.clientHeight < pointer[1])
            return;
        unselectAll.call(this);
    }

    function eventNodeMouseDown(event, node) {
        if (Element.hasClassName(Event.element(event), 'treeview_node_parent')) {
            nodeMap[this.id].expandNode = true;
            return;
        }
        if (this.options.multipleSelection && (this.selectedNodes.indexOf(node) > -1 || (event.shiftKey && this.selectedNodes.length))) {
            nodeMap[this.id].skipNodeSelect = true;
            return;
        }
        toggleSelectNode.call(this, event, node);
    }

    function eventNodeMouseUp(event, node) {
        var dragging = this.content.iwl && this.content.iwl.draggable
                ? this.content.iwl.draggable.dragging
                : false;
        if (nodeMap[this.id].skipNodeSelect && !dragging && (!this.boxSelection || !this.boxSelection.dragging)) {
            toggleSelectNode.call(this, event, node);
            delete nodeMap[this.id].skipNodeSelect;
        }
    }

    function selectNodeRange(from, to, fromPath, toPath) {
        var tree = !this.flat, depth = from.getDepth(), sibling = from, path = fromPath.clone();
        do {
            selectNode.call(this, sibling);
            if (path[depth] == toPath[depth]) {
                if (tree && sibling.childCount) {
                    if (!nodeMap[this.id][sibling.attributes.id].expanded)
                        return;
                    var child = sibling.childNodes[0];
                    path.push(0);
                    selectNodeRange.call(this, child, to, path, toPath);
                }
                return;
            }
            if (tree && sibling.childCount)
                selectDescendantNodes.call(this, sibling);
            if (sibling == to) return;
            path[depth]++;
        } while (sibling = sibling.nextSibling);
        var parentNode = from.parentNode;
        if (parentNode && parentNode.nextSibling)
            selectNodeRange.call(this, parentNode.nextSibling, to, parentNode.nextSibling.getPath(), toPath);
    }

    function selectDescendantNodes(parentNode) {
        if (!nodeMap[this.id][parentNode.attributes.id].expanded) return;
        for (var i = 0, l = parentNode.childCount; i < l; i++) {
            var child = parentNode.childNodes[i];
            selectNode.call(this, child);
            if (child.childCount)
                selectDescendantNodes.call(this, child);
        }
    }

    function toggleSelectNode(event, node) {
        var first = this.selectedNodes[0], multiple = this.options.multipleSelection, element = Event.element(event);
        if (element && Element.hasClassName(element, 'iwl-cell-editable'))
            return;
        if (event.type == 'mousedown')
            nodeMap[this.id].nodeSelected = true;
        if (!multiple || !event.ctrlKey)
            unselectAll.call(this)
        if (event.shiftKey && first && multiple) {
            var map = nodeMap[this.id];
            var fPath = first.getPath(),
                cPath = node.getPath();
            if (cPath.toString() == fPath.toString())
                return;

            var property, from, to, fromPath, toPath;
            for (var i = 0, l = fPath.length; i < l; i++) {
                if (fPath[i] == cPath[i])
                    continue;
                if (fPath[i] < cPath[i]) {
                    from = first;
                    to = node;
                    fromPath = fPath;
                    toPath = cPath;
                } else {
                    from = node;
                    to = first;
                    fromPath = cPath;
                    toPath = fPath;
                }
                break;
            }
            selectNodeRange.call(this, from, to, fromPath, toPath);
        } else if (event.ctrlKey && this.selectedNodes.length) {
            if (this.selectedNodes.indexOf(node) > -1)
                unselectNode.call(this, node);
            else
                selectNode.call(this, node);
        } else {
            selectNode.call(this, node);
        }
    }

    function selectNode(node) {
        if (!nodeMap[this.id][node.attributes.id].element.sensitive) return;
        nodeMap[this.id][node.attributes.id].element.addClassName('treeview_node_selected');
        this.selectedNodes.push(node);
        this.emitSignal('iwl:select');
    }

    function unselectNode(node, skipRemoval) {
        var view = nodeMap[this.id][node.attributes.id];
        var exists = view && view.element;
        if (exists && !view.element.sensitive) return;
        if (exists)
            view.element.removeClassName('treeview_node_selected');
        if (!skipRemoval) {
            this.selectedNodes = this.selectedNodes.without(node);
            this.emitSignal('iwl:unselect');
            if (this._focusedElement)
                this._focusedElement.blur();
        }
    }

    function unselectAll() {
        for (var i = 0, l = this.selectedNodes.length; i < l; i++)
            unselectNode.call(this, this.selectedNodes[i], true);
        this.selectedNodes = [];
        if (this._focusedElement)
            this._focusedElement.blur();
        this.emitSignal('iwl:unselect_all');
    }
    
    function boxSelectionInit(event) {
        var element = Event.element(event);
        if (element.hasClassName('iwl-cell-editable'))
            return this.boxSelection.terminateDrag();
    }

    function boxSelectionEnd(event, draggable, coords) {
        if (! event.shiftKey && !event.ctrlKey)
            unselectAll.call(this);
        var tlCoords = coords[0];
        var brCoords = coords[1];
        if (tlCoords[0] < 1) tlCoords[0] = 1;
        if (tlCoords[1] < 1) tlCoords[1] = 1;
        
        var elements = this.container.select('.iwl-node'), tNode, bNode, y1 = tlCoords[1], y2 = brCoords[1];
        while (elements && !bNode) {
            var element = elements.shift();
            var dims = [element.offsetWidth, element.offsetHeight];
            var pos = [element.offsetLeft, element.offsetTop];
            if (!tNode) {
                if (y1 >= pos[1] && y1 <= pos[1] + dims[1]) {
                    tNode = element.node;
                    selectNode.call(this, tNode);
                }
            }
            if (tNode && !bNode) {
                var node = element.node;
                selectNode.call(this, node);
                if (y2 >= pos[1] && y2 <= pos[1] + dims[1])
                    bNode = node;
            }
        }
    }

    function setDroppableNode(node, view, map) {
        var element = view.element, self = this;
        if (element.__droppableInit) return;
        element.__droppableInit = true;
        setTimeout(function() {
            element.setDragDest({accept: ['iwl-node', 'iwl-node-container'], actions: self.dropActions});
            element.signalConnect('iwl:drag_hover', map.eventDragHover);
            element.signalConnect('iwl:drag_drop', map.eventDragDrop);
        }, 5);
    }

    function unsetDroppableNode(node, view, map) {
        var element = view.element;
        if (!element.__droppableInit) return;
        element.__droppableInit = undefined;
        setTimeout(function() {
            element.unsetDragDest();
            element.signalDisconnect('iwl:drag_hover', map.eventDragHover);
            element.signalDisconnect('iwl:drag_drop', map.eventDragDrop);
        }, 5);
    }

    function eventDropMouseOver(event) {
        var element = Event.element(event);
        if (Element.hasClassName(element, 'iwl-cell-value') || Element.up(element, '.iwl-cell-value') || !this.__hoverElement)
            return;
        setElementHoverState.call(this, this.__hoverElement, hoverOverlapState.NONE);
    }

    function eventDragDrop(event, sourceElement, destElement, sourceEvent, actions) {
        var sourceView = Element.getDragData(sourceElement), dropNode = destElement.node, index, parentNode;
        switch(destElement.__hoverState) {
            case hoverOverlapState.TOP:
                var pivot = dropNode.previousSibling;
                if (pivot) index = pivot.getIndex() + 1;
                else index = 0;
                parentNode = dropNode.parentNode;
                break;
            case hoverOverlapState.BOTTOM:
                index = dropNode.getIndex();
                parentNode = dropNode.parentNode;
                break;
            case hoverOverlapState.CENTER:
                index = 0;
                parentNode = dropNode;
                break;
        }
        if (!isNaN(index)) {
            if (actions & IWL.Draggable.Actions.MOVE) {
                for (var i = sourceView.selectedNodes.length - 1; i > -1; --i)
                    this.model.move(sourceView.selectedNodes[i], index, parentNode);
            } else if (actions & IWL.Draggable.Actions.COPY) {
                for (var i = sourceView.selectedNodes.length - 1; i > -1; --i)
                    this.model.move(sourceView.selectedNodes[i].clone(), index, parentNode);
            }
        }
        unselectAll.call(sourceView);
        setElementHoverState.call(this, destElement, hoverOverlapState.NONE);
    }

    function eventDragHover(event, sourceElement, destElement) {
        var sourceView = Element.getDragData(sourceElement), dropNode = destElement.node;
        if (dropNode.isAncestor) {
            for (var i = 0, l = sourceView.selectedNodes.length; i < l; i++) {
                if (dropNode.isAncestor(sourceView.selectedNodes[i]))
                    return;
            }
        }
        if (this.selectedNodes.indexOf(dropNode) > -1)
            return;

        var vOverlap = Position.overlap('vertical', destElement);
        var state = hoverOverlapState.NONE;
        var vCenter = false;

        if (vOverlap < 0.3)
            state = hoverOverlapState.BOTTOM;
        else if (vOverlap > 0.7)
            state = hoverOverlapState.TOP;
        else
            state = hoverOverlapState.CENTER;

        setElementHoverState.call(this, destElement, state);
    }

    function eventDragInit(event, draggable) {
        draggable.options.view = IWL.Draggable.HTMLView;
        if (this.selectedNodes.length == 0)
            return draggable.terminateDrag();
        if (this.selectedNodes.length == 1) {
            var cellTemplate = cellTemplateRenderer.call(this, this.selectedNodes[0]);
            draggable.options.viewOptions = {string: generateNodeTemplate.call(this).evaluate(cellTemplate)};
        } else if (this.selectedNodes.length > 1) {
            if (this.selectedNodes[0].isDescendant) {
                var descendants = [];
                for (var i = 0, l = this.selectedNodes.length; i < l; i++) {
                    for (var j = 0, m = this.selectedNodes.length; j < m; j++) {
                        if (this.selectedNodes[i].isDescendant(this.selectedNodes[j])) {
                            descendants.push(this.selectedNodes[i]);
                            break;
                        }
                    }
                }
                for (var i = 0, l = descendants.length; i < l; i++)
                    unselectNode.call(this, descendants[i]);
            }
            var text = {text: IWL.TreeView.messages.multipleDrag.interpolate({count: "<strong>" + this.selectedNodes.length + "</strong>"})};
            draggable.options.viewOptions = {string: dragMultipleNodes.evaluate(text)};
        }

        if (this.container.scrollLeft || this.container.scrollTop) {
            Position.__includeScrollOffsets = Position.includeScrollOffsets;
            Position.includeScrollOffsets = true;
        } else if (Position.__includeScrollOffsets) {
            Position.includeScrollOffsets = Position.__includeScrollOffsets;
        }
    }

    function setElementHoverState(element, state) {
        if (this.__hoverElement && this.__hoverElement != element) {
            clearTimeout(nodeMap[this.id][this.__hoverElement.node.attributes.id].hoverExpandDelay);
            setElementHoverState.call(this, this.__hoverElement, hoverOverlapState.NONE);
        }
        if (element.__hoverState == state) return;

        var view = nodeMap[this.id][element.node.attributes.id];
        /* Can't bind and pass expandNode, since it will receive a bogus 'recursive' argument */
        if (element.node.childCount && !view.expanded && state == hoverOverlapState.CENTER)
            view.hoverExpandDelay = setTimeout(function() { this.expandNode(element.node) }.bind(this), 2000);

        if (element.__hoverState) {
            var className;
            switch(element.__hoverState) {
                case hoverOverlapState.TOP:
                    className = 'treeview_node_hover_top';
                    break;
                case hoverOverlapState.BOTTOM:
                    className = 'treeview_node_hover_bottom';
                    break;
                case hoverOverlapState.CENTER:
                    className = 'treeview_node_hover_center';
                    break;
            }
            Element.removeClassName(element, className);
        }

        element.__hoverState = state;
        var className = '';
        switch(state) {
            case hoverOverlapState.TOP:
                className = 'treeview_node_hover_top';
                break;
            case hoverOverlapState.BOTTOM:
                className = 'treeview_node_hover_bottom';
                break;
            case hoverOverlapState.CENTER:
                className = 'treeview_node_hover_center';
                break;
            default:
                this.__hoverElement = undefined;
                return;
        }
        this.__hoverElement = element;
        Element.addClassName(element, className);
    }

    function eventNodeViewHover(event) {
        if (this.__hoverElement && Event.element(event) != this.__hoverElement)
            setElementHoverState.call(this, this.__hoverElement, hoverOverlapState.NONE);
    }

    function eventNodeViewDrop(event, sourceElement, destElement) {
        var sourceView = Element.getDragData(sourceElement), dropNode = destElement.node;
        for (var i = sourceView.selectedNodes.length - 1; i > -1; --i)
            this.model.move(sourceView.selectedNodes[i]);
        unselectAll.call(sourceView);
    }

    return {
        /**
         * Sets/unsets the given items as active
         * @param path The path (or index for flat models) of the item to be set as active
         *        ...
         * @returns The object
         * */
        toggleActive: function() {
            var args = $A(arguments);
            while (args.length) {
                var path = args.shift(), node;
                if (path instanceof IWL.ListModel.Node)
                    node = path;
                else {
                    if (!Object.isArray(path)) path = [path];
                    node = this.model.getNodeByPath(path) || this.model.getFirstNode();
                }
                if (node)
                    toggleSelectNode.call(this, {ctrlKey: true}, node);
            }

            return this;
        },
        /**
         * @returns The active items of the TreeView
         * */
        getActive: function() {
            return this.selectedPaths;
        },
        /**
         * Sets the sentisitivy of the item
         * @param path The path (or index for flat models) of the item to be set as active
         * @param {Boolean} sensitive If false, the item will be insensitive
         * @returns The object
         * */
        setSensitivity: function(path, sensitive) {
            var node;
            if (path instanceof IWL.ListModel.Node) {
                node = path;
            } else {
                if (!Object.isArray(path)) path = [path];
                node = this.model.getNodeByPath(path) || this.model.getFirstNode();
            }
            if (!node) return;
            var element = nodeMap[this.id][node.attributes.id].element;
            if (!element) return;
            var hasChildren = node.childCount != 0;
            element[sensitive ? 'removeClassName' : 'addClassName'](hasChildren ? 'treeview_partial_node_insensitive' : 'treeview_node_insensitive');
            element.sensitive = !!sensitive;

            return this.emitSignal('iwl:sensitivity_change', node);
        },
        /**
         * Expands the node so its children are visible
         * @param path The path (or index for flat models) of the item to be expanded
         * @param {Boolean} recursive If true, all descendants of the node will be made visible, recursively
         * @returns The object
         * */
        expandNode: function(path, recursive) {
            if (this.flat) return;
            var node;
            if (path instanceof IWL.ListModel.Node) {
                node = path;
            } else {
                if (!Object.isArray(path)) path = [path];
                node = this.model.getNodeByPath(path) || this.model.getFirstNode();
            }
            if (!node || node.childCount == 0) return;
            var map = nodeMap[this.id], view = map[node.attributes.id];
            if (!view.element || view.expanded) return;
            if (node.childCount) {
                if (!view.childContainer)
                    createNodes.call(this, node.childNodes, generateNodeTemplate.call(this), view.indent);
                if (!view.childContainer.parentNode) {
                    var next = view.element.nextSibling;
                    next
                        ? view.element.parentNode.insertBefore(view.childContainer, next)
                        : view.element.parentNode.appendChild(view.childContainer);
                }
            }

            if (null == node.childCount && node.requestChildren({allDescendants: recursive}))
                Element.addClassName(view.element, 'treeview_node_loading');
            else {
                Element.addClassName(view.element, 'treeview_node_expanded');
                if (recursive) {
                    for (var i = 0, l = node.childCount; i < l; i++)
                        this.expandNode.bind(this, node.childNodes[i], recursive, true).defer();
                }
                if (this.options.expandEffect && !arguments[2]) {
                    Effect.toggle(
                        view.childContainer,
                        this.options.expandEffect,
                        Object.extend({
                            afterFinish: function() {
                                delete view.expanding;
                                view.expanded = true;
                            }
                        }, this.options.expandEffectOptions)
                    );
                    view.expanding = true;
                } else {
                    view.childContainer.style.display = '';
                    view.expanded = true;
                }
                this.emitSignal('iwl:node_expand', node);
            }
            return this;
        },
        /**
         * Collapses the node so its children are visible
         * @param path The path (or index for flat models) of the item to be collapsed
         * @returns The object
         * */
        collapseNode: function(path) {
            if (this.flat) return;
            var node;
            if (path instanceof IWL.ListModel.Node) {
                node = path;
            } else {
                if (!Object.isArray(path)) path = [path];
                node = this.model.getNodeByPath(path) || this.model.getFirstNode();
            }
            if (!node || node.childCount == 0) return;
            var view = nodeMap[this.id][node.attributes.id];
            if (!view.element || !view.expanded) return;
            if (this.options.expandEffect && !arguments[1]) {
                Effect.toggle(
                    view.childContainer,
                    this.options.expandEffect,
                    Object.extend({
                        afterFinish: function() {
                            for (var i = 0, l = node.childCount; i < l; i++)
                                this.collapseNode(node.childNodes[i], true);
                            view.expanded = false;
                        }.bind(this)
                    }, this.options.expandEffectOptions)
                );
            } else {
                view.childContainer.style.display = 'none';
                for (var i = 0, l = node.childCount; i < l; i++)
                    this.collapseNode(node.childNodes[i], true);
                view.expanded = false;
            }

            Element.removeClassName(view.element, 'treeview_node_expanded');
            this.emitSignal('iwl:node_collapse', node);
            return this;
        },
        /**
         * Sets the model for the view
         * @param {IWL.ObservableModel} model The model, this view will associate with. If none is given, the current model will be removed
         * @returns The object
         * */
        setModel: function(model) {
            if (this.model)
                removeModel.call(this);
            if (model instanceof IWL.ObservableModel) {
                this.model = model;
                if (this.pageControl && this.options.pageControlEventName) {
                    if (this.pageControl.loaded) {
                        setPager.call(this);
                    } else {
                        this.pageControl.signalConnect('iwl:load', setPager.bind(this));
                    }
                }

                this.flat = model instanceof IWL.ListModel && (!IWL.TreeModel || !(model instanceof IWL.TreeModel));

                normalizeCellAttributes.call(this);
                loadData.call(this, null);

                this.toggleActive.apply(this, this.options.initialActive);

                var callback = loadData.bind(this);
                this.model.signalConnect('iwl:request_children_response', requestChildren.bind(this));
                this.model.signalConnect('iwl:event_abort', eventAbort.bind(this));
                this.model.signalConnect('iwl:clear', callback);
                this.model.signalConnect('iwl:load_data', callback);
                this.model.signalConnect('iwl:sort_column_change', callback);
                this.model.signalConnect('iwl:nodes_reorder', callback);
                this.model.signalConnect('iwl:nodes_swap',  nodesSwap.bind(this));
                this.model.signalConnect('iwl:node_move',   nodeMove.bind(this));
                this.model.signalConnect('iwl:node_change', nodeChange.bind(this));
                this.model.signalConnect('iwl:node_insert', nodeInsert.bind(this));
                this.model.signalConnect('iwl:node_remove', nodeRemove.bind(this));
            }

            return this;
        },
        /**
         * @returns The TreeView's model
         * */
        getModel: function () {
            return this.model;
        },
        /**
         * Sets whether the view header is visible
         * @param {Boolean} bool If true, the header of the view will be visible
         * @returns The object
         * */
        setHeaderVisibility: function(bool) {
            if (bool) {
                if (!this.header.__built) {
                    createHeader.call(this);
                    this.header.__built = true;
                }
                this.header.style.display = '';
            } else {
                this.header.style.display = 'none';
            }

            return this;
        },
        /**
         * Returns true of the header is visible
         * */
        getHeaderVisibility: function() {
            return this.header.visible();
        },

        /**
         * Enables/Disables icon dragging for the Icon View
         * @param {Boolean} bool If true, dragging will be enabled for the Icon View
         * @param {Bitmask} actions The drag source actions. See IWL.Draggable.Actions
         * @returns The object
         * */
        setModelDragSource: function(bool, actions) {
            if (this.options.dragSource == (bool = !!bool))
                return;

            this.options.dragSource = bool;
            var map = nodeMap[this.id];
            if (!map.eventDragInit)
                map.eventDragInit = eventDragInit.bind(this);
            this.dragActions = actions || IWL.Draggable.Actions.MOVE;

            if (bool) {
                this.content.setDragSource({revert: true, revertEffect: false, actions: this.dragActions});
                this.content.setDragData(this);
                this.content.signalConnect('iwl:drag_init', map.eventDragInit);
            } else {
                this.content.unsetDragSource();
                this.content.signalDisconnect('iwl:drag_init', map.eventDragInit);
            }

            if (Prototype.Browser.IE && this.boxSelection) {
                this.boxSelection.destroy();
                this.boxSelection = new IWL.BoxSelection(this.content, {boxOpacity: this.options.boxSelectionOpacity});
            }

            return this;
        },
        /**
         * @returns True, if the Icon View is a drag source
         * */
        getModelDragSource: function() {
            return this.options.dragSource;
        },
        /**
         * Enables/Disables icon dropping for the Icon View
         * @param {Boolean} bool If true, icon dropping will be enabled for the Icon View
         * @param {Bitmask} actions The drag source actions. See IWL.Draggable.Actions
         * @returns The object
         * */
        setModelDragDest: function(bool, actions) {
            if (this.options.dragDest == (bool = !!bool))
                return;

            this.options.dragDest = bool;
            var map = nodeMap[this.id];
            if (!map.eventDragHover)
                map.eventDragHover = eventDragHover.bind(this);
            if (!map.eventDragDrop)
                map.eventDragDrop = eventDragDrop.bind(this);
            if (!map.eventDropMouseOver)
                map.eventDropMouseOver = eventDropMouseOver.bind(this);
            if (!map.eventNodeViewHover)
                map.eventNodeViewHover = eventNodeViewHover.bind(this);
            if (!map.eventNodeViewDrop)
                map.eventNodeViewDrop = eventNodeViewDrop.bind(this);

            this.dropActions = actions || IWL.Draggable.Actions.MOVE;

            if (bool) {
                this.content.setDragDest({accept: ['iwl-node', 'iwl-node-container'], actions: this.dropActions});
                this.content.signalConnect('iwl:drag_hover', map.eventNodeViewHover);
                this.content.signalConnect('iwl:drag_drop', map.eventNodeViewDrop);
                this.content.signalConnect('mouseover', map.eventDropMouseOver);
                this.content.signalConnect('mouseout', map.eventDropMouseOver);
            } else {
                this.content.unsetDragDest();
                this.content.signalDisconnect('iwl:drag_hover', map.eventNodeViewHover);
                this.content.signalDisconnect('iwl:drag_drop', map.eventNodeViewDrop);
                this.content.signalDisconnect('mouseover', map.eventDropMouseOver);
                this.content.signalDisconnect('mouseout', map.eventDropMouseOver);
            }

            var self = this;
            self.model._each(function(node) {
                var view = map[node.attributes.id];
                if (!view) return;
                bool
                    ? setDroppableNode.call(self, node, view, map)
                    : unsetDroppableNode.call(self, node, view, map);
            });
            
            return this;
        },
        /**
         * @returns True, if the Icon View is a drag destination
         * */
        getModelDragDest: function() {
            return this.options.dragDest;
        },
        /**
         * Sets whether the user can reorder the model by dragging/dropping icons
         * @param {Boolean} bool If true, the user can drag icons in order to reorder the model
         * @returns The object
         * */
        setReorderable: function(bool) {
            bool = !!bool;
            if (this.options.reorderable == bool)
                return;

            this.options.reorderable = bool;
            this.setModelDragSource(bool);
            this.setModelDragDest(bool);
            return this;
        },
        /**
         * @returns True, if the icons can be reordered by dragging
         * */
        getReorderable: function() {
            return this.options.reorderable;
        },

        _init: function(model) {
            this.options = Object.extend({
                columnWidth: [],
                columnClass: [],
                cellAttributes: [],
                initialPath: [],
                popUpDelay: 0.2,
                headerVisible: true,
                drawExpanders: true,
                expandEffect: 'blind',
                expandEffectOptions: {duration: 0.2},
                boxSelectionOpacity: 0.5,
                multipleSelection: false,
                boxSelection: true
            }, arguments[1]);
            this.header = this.down('.treeview_header');
            this.content = this.container = this.down('.treeview_content');
            this.container.childContainers = [];
            this.selectedNodes = [];
            this.containers = {};
            if (this.options.pageControl) {
                this.pageControl = $(this.options.pageControl);
                this.pageControl.signalConnect('iwl:current_page_is_changing', pageChanging.bind(this));
                this.pageControl.signalConnect('iwl:current_page_change', pageChange.bind(this));
            }

            connectSignals.call(this);

            nodeMap[this.id] = {};

            this.nodeSeparatorCallback = Object.isString(this.options.nodeSeparatorCallback)
                ? this.options.nodeSeparatorCallback.objectize()
                : Object.isFunction(this.options.nodeSeparatorCallback)
                    ? this.options.nodeSeparatorCallback : null;

            if (model) {
                if (Object.keys(model.options.columnTypes).length)
                    IWL.ListModel.overrideDefaultDataTypes(model.options.columnTypes);
                if (!(model instanceof IWL.ListModel))
                    model = new (model.classType.objectize())(model);
                this.setModel(model);
            }

            if (this.options.multipleSelection && this.options.boxSelection) {
                this.boxSelection = new IWL.BoxSelection(this.content, {boxOpacity: this.options.boxSelectionOpacity});
                if (this.options.editable)
                    this.signalConnect('iwl:box_selection_init', boxSelectionInit.bind(this));
            }

            if (window.attachEvent)
                window.attachEvent("onunload", function() {
                    this.model = null;
                    nodeMap[this.id] = {};
                    if (this.boxSelection)
                        this.boxSelection.destroy();
                }.bind(this));

            if (this.options.headerVisible) {
                if (!this.model)
                    normalizeCellAttributes.call(this);
                this.setHeaderVisibility(true);
            }

            this.signalConnect('mousedown', eventMouseDown.bind(this));
            this.signalConnect('iwl:box_selection_end', boxSelectionEnd.bind(this));

            this.emitSignal('iwl:load');
        }
    }
})());
IWL.TreeView.messages = {
    multipleDrag: "#{count} selected nodes"
};
