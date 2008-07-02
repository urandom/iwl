// vim: set autoindent shiftwidth=4 tabstop=8:
IWL.TreeView = Object.extend(Object.extend({}, IWL.Widget), (function () {
    var nodeMap = {};

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
            node.push('<td class="', classNames.join(' '), '"', width, '>#{column', i, '}</td>');
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

    function setNodeAttributes(container, element, node) {
        var id = this.id, nId = node.attributes.id;
        if (!nodeMap[id][nId]) nodeMap[id][nId] = {};
        var nView = nodeMap[id][nId];
        Object.extend(nView, {
            node: node,
            element: element,
            container: container
        });
        element.node = node;
        if (element.hasClassName('treeview_node_separator'))
            return;

        element.sensitive = true;
        element.signalConnect('dom:mouseenter', function(event) {
            changeHighlight.call(this, node);
        }.bind(this));
        element.signalConnect('dom:mouseleave', function(event) {
            changeHighlight.call(this);
        }.bind(this));

        if (node.attributes.insensitive)
            this.setSensitivity(node, false);
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
                    className: 'treeview_node_container treeview_node_container_depth' + path.length
                });
            this.containers[pathString] = container;
            container.path = pathString;

            nodeMap[id][nId].childContainer = container;
            container.parentContainer = parentNode.parentNode
                                     && nodeMap[id][parentNode.parentNode.attributes.id].childContainer
                ? nodeMap[id][parentNode.parentNode.attributes.id].childContainer
                : this.container;
            container.parentContainer.childContainers.push(container);
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
        template.nodePosition = 'treeview_header_node';
        html = template.evaluate(headerTemplate);
        this.header.innerHTML = html;
    }

    function recreateNode(node, template, container) {
        var cellTemplate = cellTemplateRenderer.call(this, node), html, id = this.id;
        if (cellTemplate.separator) {
            html = generateSeparator.call(this);
        } else {
            if (!node.previousSibling && !node.nextSibling)
                cellTemplate.nodePosition = 'treeview_node_first treeview_node_last'
            else if (!node.previousSibling)
                cellTemplate.nodePosition = 'treeview_node_first'
            else if (!node.nextSibling)
                cellTemplate.nodePosition = 'treeview_node_last'
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
        var element = next ? map[next.attributes.id].element.previousSibling : container.lastChild;
        var values = [], cMap = this.options.columnMap;
        for (var j = 0, l = cMap.length; j < l; j++) {
            var index = cMap[j];
            values.push(node.values[index]);
        }
        setNodeAttributes.call(this, container, element, node);
        cellFunctionRenderer.call(this, element.rows[0].cells, values, node);
    }

    function createNodes(nodes, template) {
        var html = [], container, nodeLength = nodes.length;
        var container = createContainer.call(this, nodes[0] ? nodes[0].parentNode : null);
        for (var i = 0, node = nodes[0]; i < nodeLength; node = nodes[++i]) {
            var cellTemplate = cellTemplateRenderer.call(this, node);
            if (cellTemplate.separator) {
                html.push(generateSeparator.call(this));
                continue;
            }

            if (i + 1 == nodeLength && i == 0)
                cellTemplate.nodePosition = 'treeview_node_first treeview_node_last'
            else if (i == 0)
                cellTemplate.nodePosition = 'treeview_node_first'
            else if (i + 1 == nodeLength)
                cellTemplate.nodePosition = 'treeview_node_last'
            html.push(template.evaluate(cellTemplate));
        };
        container.innerHTML = html.join('');
        var children = container.childElements();
        for (var i = 0; i < nodeLength; i++) {
            var values = [], cMap = this.options.columnMap, node = nodes[i];
            for (var j = 0, l = cMap.length; j < l; j++) {
                var index = cMap[j];
                values.push(node.values[index]);
            }
            setNodeAttributes.call(this, container, children[i], node);
            cellFunctionRenderer.call(this, children[i].rows[0].cells, values, node);
        }
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
                        cAttrs.templateRenderer = new IWL.CellTemplateRenderer.Checkbox(options);
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

    function loadData(event, parentNode) {
        var template = generateNodeTemplate.call(this);
        if (parentNode) {
            var view = nodeMap[this.id][parentNode.attributes.id];
            var highlight = view.element.highlight;
            recreateNode.call(this, parentNode, template, view.container);
            if (highlight) {
                changeHighlight.call(this, parentNode);
            }
        } else {
            createNodes.call(this, this.model.rootNodes, template);
        }
    }

    function eventAbort(event, eventName, params, options) {
        if (eventName == 'IWL-TreeModel-requestChildren') {
            var node = this.model.getNodeByPath(options.parentNode);
            var element = nodeMap[this.id][node.attributes.id].element;
            var arrow = element.down('.treeview_partial_loading');
            arrow.removeClassName('treeview_partial_loading').addClassName('treeview_partial_parental_arrow');
            var callback = function(event) {
                element.signalDisconnect('dom:mouseenter', callback);
                if (node.requestChildren())
                    arrow.removeClassName('treeview_partial_parental_arrow').addClassName('treeview_partial_loading');
                else arrow.remove();
            }.bind(this);
            element.signalConnect('dom:mouseenter', callback);
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
        if (view.element && view.element.parentNode == previousParent)
            view.element.remove();

        nodeInsert.call(this, event, node, parentNode);
    }

    function nodeChange(event, node, columns) {
        var view = nodeMap[this.id][node.attributes.id], cMap = this.options.columnMap, change = false;
        if (columns) {
            for (var i = 0, l = columns.length; i < l; i++) {
                var index = cMap.indexOf(columns[i]);
                if (index == -1) continue;
                if (this.model.columns[columns[i]].type == IWL.ListModel.DataType.BOOLEAN) {
                    var input = view.element.down('.treeview_column' + index + ' input');
                    var value = node.values[columns[i]];
                    if (value == input.checked) continue;
                }
                change = true;
            }
        } else change = true;
        if (!change) return;
        var template = generateNodeTemplate.call(this)
        var highlight = view.element.highlight;
        recreateNode.call(this, node, template, view.container);
        if (highlight) {
            changeHighlight.call(this, node);
        }
    }

    function nodeInsert(event, node, parentNode) {
        var template = generateNodeTemplate.call(this)
        var id = this.id, nId = node.attributes.id;
        var container = parentNode ? createContainer.call(this, parentNode) : this.container;
        if (!nodeMap[id][nId]) nodeMap[id][nId] = {};
        if (!node.nextSibling && node.previousSibling)
            nodeMap[id][node.previousSibling.attributes.id].element.removeClassName('treeview_node_last');
        recreateNode.call(this, parentNode || node, template, container);
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
            recreateNode.call(this, parentNode || node, template, container);
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
        this.pageControl.bindToWidget($(this.model.options.id), this.options.pageControlEventName)
    }

    function toggleSelectNode(event, node) {
        var first = this.selectedNodes[0];
        if (event.type == 'mousedown')
            nodeMap[this.id].iconSelected = true;
        if (!event.ctrlKey && !event.shiftKey && this.selectedNodes.indexOf(node) > -1)
            return;
        if (!event.ctrlKey)
            unselectAll.call(this)
        if (event.shiftKey && first) {
            var map = nodeMap[this.id];
            var fIndex = first.getIndex();
            var cIndex = node.getIndex();
            if (cIndex == fIndex)
                return selectNode.call(this, node);

            var property = fIndex < cIndex ? 'nextSibling' : 'previousSibling';
            var sibling = first;
            for (var i = 0, l = Math.abs(fIndex - cIndex) + 1; i < l; i++) {
                selectNode.call(this, sibling);
                sibling = sibling[property];
            }
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
        nodeMap[this.id][node.attributes.id].element.addClassName('iconview_node_selected');
        this.selectedNodes.push(node);
        this.emitSignal('iwl:select');
    }

    function unselectNode(node, skipRemoval) {
        var view = nodeMap[this.id][node.attributes.id];
        var exists = view && view.element;
        if (exists && !view.element.sensitive) return;
        if (exists)
            view.element.removeClassName('iconview_node_selected');
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
                if (path instanceof IWL.ListModel.Node) {
                    node = path;
                    this.selectedPaths.push(node.getPath());
                } else {
                    this.selectedPaths.push(path);
                    if (!Object.isArray(path)) path = [path];
                    node = this.model.getNodeByPath(path) || this.model.getFirstNode();
                }
                if (node)
                    toggleSelectNode.call(this, {ctrlKey: true}, node);
            }

            return this;
        },
        /**
         * @returns The active items of the IconView
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

        _init: function(model) {
            this.options = Object.extend({
                columnWidth: [],
                columnClass: [],
                cellAttributes: [],
                initialPath: [],
                maxHeight: 400,
                popUpDelay: 0.2,
                headerVisible: true
            }, arguments[1]);
            this.header = this.down('.treeview_header');
            this.container = this.down('.treeview_content');
            this.containers = {};
            if (this.options.pageControl) {
                this.pageControl = $(this.options.pageControl);
                this.pageControl.signalConnect('iwl:current_page_is_changing', pageChanging.bind(this));
                this.pageControl.signalConnect('iwl:current_page_change', pageChange.bind(this));
            }

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

            if (window.attachEvent)
                window.attachEvent("onunload", function() {
                    this.model = null;
                    nodeMap[this.id] = {};
                }.bind(this));

            if (this.options.headerVisible) {
                if (!this.model)
                    normalizeCellAttributes.call(this);
                this.setHeaderVisibility(true);
            }

            this.emitSignal('iwl:load');
        }
    }
})());
