// vim: set autoindent shiftwidth=4 tabstop=8:
IWL.ComboView = Object.extend(Object.extend({}, IWL.Widget), (function () {
    var nodeMap = {};

    function loadData(event) {
        if (arguments[1]) return;
        var template = generateNodeTemplate.call(this)
        createNodes.call(this, this.model.rootNodes, template, flat);
        this.setActive(this.options.initialPath);
    }

    function generateNodeTemplate() {
        var node = ['<td cellpadding="0" cellspacing="0" class="iconview_node #{nodePosition}" iwl:nodePath="#{nodePath}">'];
        node.push('<img class="iconview_node_image" alt="#{alt}" src="#{src}" /><p class="iconview_node_text #{orientation}">#{text}</p></td>');

        return new Template(node.join(''));
    }

    function cellTemplateRenderer(node) {
        var cellTemplate = {}, values = [], cMap = this.columnMap, mappedValues = {};
        for (var i = 0, l = cMap.length; i < l; i++)
            values.push(node.values[cMap[i]]);
        for (var i = 0, l = node.values.length; i < l; i++)
            mappedValues['value' + i] = node.values[i];
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
        var id = this.id, nId = node.attributes.id;
        if (!nodeMap[id][nId]) nodeMap[id][nId] = {};
        var nView = nodeMap[id][nId];
        Object.extend(nView, {
            node: node,
            element: element,
            container: container
        });
        var childContainer = nView.childContainer;
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
                    className: 'comboview_node_container comboview_node_container_depth' + path.length
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
                container = new Element('div', {className: 'comboview_node_container'});
                container.childContainers = [];
            }
            if (this.pageControl && !container.pageContainer && !this.options.placedPageControl) {
                var pageContainer = new Element('div', {className: 'comboview_page_container'});
                pageContainer.appendChild(container);
                pageContainer.appendChild(this.pageControl);
                this.pageControl.setStyle({position: '', left: ''});
                container.pageContainer = pageContainer;
            }
            this.container = container;
        }
        return container;
    }

    function recreateNode(node, template, flat, container) {
        var cellTemplate = cellTemplateRenderer.call(this, node), html, nodePath = node.getPath().toJSON(), id = this.id;
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
        var values = [], types = [], cMap = this.columnMap;
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
            var values = [], types = [], cMap = this.columnMap, node = nodes[i];
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
        if (this.pageChanging || !this.model) return;
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

    function changeHighlight(node) {
        var current = this.currentNodeHighlight;
        if (current) {
            var element = nodeMap[this.id][current.attributes.id].element;
            element.removeClassName('comboview_node_highlight');
            element.highlight = false;
        }
        if (node) {
            var element = nodeMap[this.id][node.attributes.id].element;
            if (element.sensitive || node.childCount != 0)
                element.addClassName('comboview_node_highlight');
            element.highlight = true;
        }
        this.currentNodeHighlight = node;
    }

    function normalizeCellAttributes() {
        for (var i = 0, l = this.columnMap.length; i < l; i++) {
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
        var container = this.container.pageContainer || this.container;
        IWL.View.disable({element: container && container.visible() ? container: null});
    }

    function pageChange() {
        IWL.View.enable();
        this.pageChanging = undefined;
        if (this.popDownRequest) {
            this.popDownRequest = undefined;
            this.popDown();
        }
    }

    function eventAbort(event, eventName, params, options) {
        if (eventName == 'IWL-TreeModel-requestChildren') {
            var node = this.model.getNodeByPath(options.parentNode);
            var element = nodeMap[this.id][node.attributes.id].element;
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

    function nodeChange(event, node) {
        var flat = this.model.isFlat(), view = nodeMap[this.id][node.attributes.id];
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
        var id = this.id, nId = node.attributes.id;
        var container = parentNode ? createContainer.call(this, parentNode) : this.container;
        if (!nodeMap[id][nId]) nodeMap[id][nId] = {};
        if (!node.nextSibling && node.previousSibling)
            nodeMap[id][node.previousSibling.attributes.id].element.removeClassName('comboview_node_last');
        recreateNode.call(this, parentNode || node, template, flat, container);
        generatePathAttributes.call(this, parentNode);
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
            var element = nodeMap[this.id][child.attributes.id].element;
            element.writeAttribute('iwl:nodePath', Object.toJSON(path));
            if (child.childNodes.length)
                generatePathAttributes.call(this, child);
        }
    }

    function removeModel() {
        this.popDown();
        removeContainers.call(this, this.container);
        nodeMap[this.id] = {};
        this.model = this.container = undefined;
    }

    return {
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
            if (!node || !nodeMap[this.id][node.attributes.id].element.sensitive) return;
            this.content.removeClassName('comboview_content_empty');
            this.values = node.getValues();
            var cellTemplate = cellTemplateRenderer.call(this, node);

            return this.emitSignal('iwl:change', this.values);
        ,
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
            var element = nodeMap[this.id][node.attributes.id].element;
            if (!element) return;
            var hasChildren = node.childCount != 0;
            element[sensitive ? 'removeClassName' : 'addClassName'](hasChildren ? 'comboview_partial_node_insensitive' : 'comboview_node_insensitive');
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
                loadData.call(this);
            }

            return this;
        },
        /**
         * @returns The ComboView's model
         * */
        getModel: function () {
            return this.model;
        },

        _init: function(id, model) {
            this.options = Object.extend({
                columns: [],
                cellAttributes: [],
                initialPath: [],
                orientation: IWL.IconView.Orientation.VERTICAL
            }, arguments[2]);
            if (Object.keys(model.options.columnTypes).length)
                IWL.TreeModel.overrideDefaultDataTypes(model.options.columnTypes);
            this.model = new IWL.TreeModel(model);
            if (this.options.pageControl) {
                this.pageControl = $(this.options.pageControl);
                this.pageControl.signalConnect('iwl:current_page_is_changing', pageChanging.bind(this));
                this.pageControl.signalConnect('iwl:current_page_change', pageChange.bind(this));
            }
            if (this.pageControl && this.options.pageControlEventName)
                this.pageControl.loaded
                    ? this.pageControl.bindToWidget($(this.model.options.id), this.options.pageControlEventName)
                    : this.pageControl.signalConnect('iwl:load', function() {
                            this.pageControl.bindToWidget($(this.model.options.id), this.options.pageControlEventName)
                      }.bind(this));

            nodeMap[id] = {};

            if (window.attachEvent)
                window.attachEvent("onunload", function() {
                    this.model = null;
                    nodeMap[id] = {};
                });

            normalizeCellAttributes.call(this);
            loadData.call(this);
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

            this.emitSignal('iwl:load');
        }
    }
})());

IWL.IconView.Orientation = (function () {
    var index = 0;

    return {
        HORIZONTAL: 1 << index++,
        VERTICAL: 1 << index++
    }
})();
