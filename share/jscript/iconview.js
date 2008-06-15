// vim: set autoindent shiftwidth=4 tabstop=8:
IWL.IconView = Object.extend(Object.extend({}, IWL.Widget), (function () {
    var nodeMap = {}, names = ['imageColumn', 'textColumn'], types = [IWL.ListModel.DataTypes.IMAGE, IWL.ListModel.DataTypes.STRING],
        imageTemplate = new Template('<img class="iconview_node_image" src="#{src}" alt="#{alt}" />'),
        hTextTemplate = new Template('<span class="iconview_node_text iconview_node_text_vertical">#{text}</span>');
        vTextTemplate = new Template('<p class="iconview_node_text iconview_node_text_horizontal">#{text}</p>');
        nodeTemplate  = new Template('<div style="#{nodeStyle}" class="iconview_node #{nodePosition}" iwl:nodePath="#{nodePath}">#{imageColumn}#{textColumn}</div>');
        rowSeparator  = '<div class="iwl-clear iconview_row_separator"></div>';

    function loadData(event) {
        createNodes.call(this, this.model.rootNodes);
    }

    function cellTemplateRenderer(node) {
        var cellTemplate = {}, mappedValues = {},
            nValues = node.getValues(this.options.imageColumn, this.options.textColumn);
        for (var i = 0, l = node.values.length; i < l; i++)
            mappedValues['value' + i] = node.values[i];
        for (var i = 0, l = nValues.length; i < l; i++) {
            var render = this.options.cellAttributes[i].renderTemplate;
            if (render) {
                render = new Template(render);
                var options = Object.extend(Object.clone(mappedValues), {cellValue: nValues[i]});
                cellTemplate[names[i]] = render.evaluate(options);
            } else {
                if (nValues[i] == null)
                    continue;
                var type = this.model.columns[this.options[names[i]]];
                if (type) type = type.type;
                if (names[i] == 'imageColumn' && type == IWL.ListModel.DataTypes.IMAGE)
                    cellTemplate.imageColumn = imageTemplate.evaluate(nValues[i]);
                else if (names[i] == 'textColumn' && type == IWL.ListModel.DataTypes.STRING) {
                    if (this.options.orientation == IWL.IconView.Orientation.HORIZONTAL)
                        cellTemplate.textColumn = hTextTemplate.evaluate({text: nValues[i]});
                    else
                        cellTemplate.textColumn = vTextTemplate.evaluate({text: nValues[i]});
                }
            }
        }
        return cellTemplate;
    }

    function setNodeAttributes(element, node) {
        var id = this.id, nId = node.attributes.id;
        if (!nodeMap[id][nId]) nodeMap[id][nId] = {};
        var nView = nodeMap[id][nId];
        Object.extend(nView, {
            node: node,
            element: element
        });
        element.sensitive = true;

        if (node.attributes.insensitive)
            this.setSensitivity(node, false);
    }

    function cellFunctionRenderer(cells, values, node) {
        for (var i = 0, l = values.length; i < l; i++) {
            var attributes = this.options.cellAttributes[i];
            var render = attributes.renderFunction;
            if (!render) continue;
            render.call(attributes.renderInstance || this, cells[i], values[i], types[i], node);
        }
    }

    function recreateNode(node) {
        var cellTemplate = cellTemplateRenderer.call(this, node), nodePath = node.getPath().toJSON(), id = this.id;
        var bugs = Prototype.Browser.IE ? 3 * this.options.colums : Prototype.Browser.Gecko ? this.options.columns : 0;
        var width = this.options.columns > 0
            ? 'width: ' + (this.offsetWidth / this.columns - this.iconMargin - bugs) + 'px;'
            : 'width: ' + this.options.columnWidth + 'px;';

        cellTemplate.nodeStyle = width;
        if (!node.previousSibling && !node.nextSibling)
            cellTemplate.nodePosition = 'iconview_node_first iconview_node_last'
        else if (!node.previousSibling)
            cellTemplate.nodePosition = 'iconview_node_first'
        else if (!node.nextSibling)
            cellTemplate.nodePosition = 'iconview_node_last'
        cellTemplate.nodePath = nodePath;
        var html = nodeTemplate.evaluate(cellTemplate);
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
                this.innerHTML = html;
        }
        replaceRowSeparators.call(this);
        element = next ? map[next.attributes.id].element.previous('.iconview_node') : this.lastChild;
        var values = node.getValues(this.options.imageColumn, this.options.textColumn);
        setNodeAttributes.call(this, element, node);
        cellFunctionRenderer.call(this, element, values, node);
    }

    function createNodes(nodes) {
        var html = [], nodeLength = nodes.length, column = 0;
        var bugs = Prototype.Browser.IE ? 3 * this.options.colums : Prototype.Browser.Gecko ? this.options.columns : 0;
        var width = this.options.columns > 0
            ? 'width: ' + (this.offsetWidth / this.columns - this.iconMargin - bugs) + 'px;'
            : 'width: ' + this.options.columnWidth + 'px;';
        for (var i = 0, node = nodes[0]; i < nodeLength; node = nodes[++i]) {
            var cellTemplate = cellTemplateRenderer.call(this, node);

            cellTemplate.nodeStyle = width;
            if (i + 1 == nodeLength && i == 0)
                cellTemplate.nodePosition = 'iconview_node_first iconview_node_last'
            else if (i == 0)
                cellTemplate.nodePosition = 'iconview_node_first'
            else if (i + 1 == nodeLength)
                cellTemplate.nodePosition = 'iconview_node_last'
            cellTemplate.nodePath = node.getPath().toJSON();
            html.push(nodeTemplate.evaluate(cellTemplate));
            ++column;
            if (column == this.columns) {
                html.push(rowSeparator);
                column = 0;
            }
        };
        html.push(rowSeparator);
        this.innerHTML = html.join('');
        var children = this.select('.iconview_node');
        for (var i = 0; i < nodeLength; i++) {
            var node = nodes[i];
            var values = node.getValues(this.options.imageColumn, this.options.textColumn);
            setNodeAttributes.call(this, children[i], node);
            cellFunctionRenderer.call(this, children[i], values, node);
        }
    }

    function normalizeCellAttributes() {
        for (var i = 0, l = types.length; i < l; i++) {
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
        IWL.View.disable({element: this.pageContainer || this});
    }

    function pageChange() {
        IWL.View.enable();
        this.pageChanging = undefined;
    }

    function nodesSwap(event, node1, node2) {
        var n1View = nodeMap[this.id][node1.attributes.id],
            n2View = nodeMap[this.id][node2.attributes.id];

        n1View.element.remove();
        nodeChange.call(this, event, node1);

        n2View.element.remove();
        nodeChange.call(this, event, node2);
    }

    function nodeMove(event, node) {
        var view = nodeMap[this.id][node.attributes.id];
        if (view.element && view.element.parentNode)
            view.element.remove();

        nodeInsert.call(this, event, node);
    }

    function nodeChange(event, node) {
        recreateNode.call(this, node);
    }

    function nodeInsert(event, node) {
        var id = this.id, nId = node.attributes.id;
        if (!nodeMap[id][nId]) nodeMap[id][nId] = {};
        if (!node.nextSibling && node.previousSibling)
            nodeMap[id][node.previousSibling.attributes.id].element.removeClassName('iconview_node_last');
        recreateNode.call(this, node);
        generatePathAttributes.call(this);
    }

    function nodeRemove(event, node) {
        var view = nodeMap[this.id][node.attributes.id];
        var element = view.element;

        element.remove();

        if (this.model.rootNodes.length) {
            generatePathAttributes.call(this);
            replaceRowSeparators.call(this);
        } else
            recreateNode.call(this, node);
    }
    
    function generatePathAttributes() {
        var nodes = this.model.rootNodes;
        for (var i = 0, l = nodes.length; i < l; i++) {
            var node = nodes[i];
            var element = nodeMap[this.id][node.attributes.id].element;
            element.writeAttribute('iwl:nodePath', '[' + i + ']');
        }
    }

    function removeModel() {
        nodeMap[this.id] = {};
        this.model = undefined;
    }

    function setPager() {
        this.pageControl.unbind();
        this.pageControl.bindToWidget($(this.model.options.id), this.options.pageControlEventName)
        if (!this.pageContainer && !this.options.placedPageControl) {
            var pageContainer = new Element('div', {className: 'iconview_page_container'});
            this.insert({after: pageContainer});
            pageContainer.appendChild(this);
            pageContainer.appendChild(this.pageControl);
            this.pageControl.setStyle({position: '', left: ''});
            this.pageContainer = pageContainer;
        }
    }

    function getIconMargin() {
        var div = new Element('div');
        div.innerHTML = nodeTemplate.evaluate({});
        var icon = div.firstChild;
        this.iconMargin = parseFloat(icon.getStyle('margin-left')) + parseFloat(icon.getStyle('margin-right'));
    }

    function replaceRowSeparators() {
        var elements = this.childElements(), nodes = [];
        for (var i = 0, l = elements.length; i < l; i++) {
            var element = elements[i];
            if (element.hasClassName('iconview_node'))
                nodes.push(element);
            else if (element.hasClassName('iconview_row_separator'))
                element.remove();
        }
        for (var i = 0, j = 0, l = nodes.length; i < l; i++) {
            if (++j == this.columns) {
                j = 0;
                nodes[i].insert({after: rowSeparator});
            } else if (i == l - 1) {
                nodes[i].insert({after: rowSeparator});
            }
        }
    }

    return {
        /**
         * Sets the active item of the IconView
         * @param path The path (or index for flat models) of the item to be set as active
         * @returns The object
         * */
        setActive: function(path) {
            var node;
            if (path instanceof IWL.ListModel.Node) {
                node = path;
                this.selectedPath = node.getPath();
            } else {
                this.selectedPath = path;
                if (!Object.isArray(path)) path = [path];
                node = this.model.getNodeByPath(path) || this.model.getFirstNode();
            }
            if (!node || !nodeMap[this.id][node.attributes.id].element.sensitive) return;
            this.content.removeClassName('iconview_content_empty');
            this.values = node.getValues();
            var cellTemplate = cellTemplateRenderer.call(this, node);

            return this.emitSignal('iwl:change', this.values);
        },
        /**
         * @returns The active item of the IconView
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
            element[sensitive ? 'removeClassName' : 'addClassName'](hasChildren ? 'iconview_partial_node_insensitive' : 'iconview_node_insensitive');
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

                loadData.call(this, null);

                var callback = loadData.bind(this);
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
         * @returns The IconView's model
         * */
        getModel: function () {
            return this.model;
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
            if (this.options.pageControl) {
                this.pageControl = $(this.options.pageControl);
                this.pageControl.signalConnect('iwl:current_page_is_changing', pageChanging.bind(this));
                this.pageControl.signalConnect('iwl:current_page_change', pageChange.bind(this));
            }

            getIconMargin.call(this);
            this.columns = this.options.columns
                        || parseInt(this.offsetWidth / this.options.columnWidth);
            nodeMap[id] = {};

            normalizeCellAttributes.call(this);

            if (model) {
                if (Object.keys(model.options.columnTypes).length)
                    IWL.ListModel.overrideDefaultDataTypes(model.options.columnTypes);
                if (!(model instanceof IWL.ListModel))
                    model = new (model.classType.objectize())(model);
                this.setModel(model);
            }

            this.state = 0;

            if (window.attachEvent)
                window.attachEvent("onunload", function() {
                    this.model = null;
                    this.pageContainer = null;
                    nodeMap[id] = {};
                });

            this.emitSignal('iwl:load');
        }
    }
})());

IWL.IconView.Orientation = {
    HORIZONTAL: 0,
    VERTICAL: 1
};
IWL.IconView.CellType = {
    TEXT: 0,
    IMAGE: 1
};
