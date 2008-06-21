// vim: set autoindent shiftwidth=4 tabstop=8:
IWL.IconView = Object.extend(Object.extend({}, IWL.Widget), (function () {
    var nodeMap = {}, names = ['imageColumn', 'textColumn'], types = [IWL.ListModel.DataTypes.IMAGE, IWL.ListModel.DataTypes.STRING],
        nodeTemplate  = new Template('<div style="#{nodeStyle}" class="iconview_node #{nodePosition}" iwl:nodePath="#{nodePath}">#{imageColumn}#{textColumn}</div>');
        dragMultipleIcons = new Template('<span class="iconview_dragged_nodes"><strong>#{number}</strong> #{text}</span>'),
        rowSeparator  = '<div class="iwl-clear iconview_row_separator"></div>',
        scrollbarSize = document.viewport.getScrollbarSize(),
        hoverOverlapState = {
            NONE:   0,
            TOP:    1,
            RIGHT:  2,
            BOTTOM: 3,
            LEFT:   4,
            CENTER: 5
        };

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
                var template = this.options.cellAttributes[i].templateRenderer;
                if (template)
                    cellTemplate[names[i]] = template.render(nValues[i], node);
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
        var children = element.childElements();
        for (var i = 0, l = children.length; i < l; i++) {
            var child = children[i];
            child.signalConnect('mouseover', function(event) {
                if ((this.boxSelection && this.boxSelection.dragging) || (this.iwl && this.iwl.draggable && this.iwl.draggable.dragging) || !element.sensitive) return;
                changeHighlight.call(this, node);
            }.bind(this));
            child.signalConnect('mouseout', function(event) {
                if ((this.boxSelection && this.boxSelection.dragging) || (this.iwl && this.iwl.draggable && this.iwl.draggable.dragging) || !element.sensitive) return;
                changeHighlight.call(this);
            }.bind(this));
            child.signalConnect('mousedown', eventIconMouseDown.bindAsEventListener(this, node));
            child.signalConnect('mouseup', eventIconMouseUp.bindAsEventListener(this, node));
        }
    }

    function cellFunctionRenderer(cells, values, node) {
        for (var i = 0, l = values.length; i < l; i++) {
            var attributes = this.options.cellAttributes[i];
            var render = attributes.renderFunction;
            if (!render) continue;
            render.call(attributes.renderInstance || this, cells[i], values[i], node);
        }
    }

    function recreateNode(node) {
        var cellTemplate = cellTemplateRenderer.call(this, node), nodePath = node.getPath().toJSON(), id = this.id;
        var bugs = Prototype.Browser.IE ? 3 * this.options.colums : Prototype.Browser.Gecko ? this.options.columns : 0;
        this.columnWidth = this.options.columns > 0
            ? this.offsetWidth / this.columns - this.iconMarginX - bugs
            : this.options.columnWidth;
        var width = 'width: ' + this.columnWidth + 'px;';

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
        if (this.options.dragDest)
            setDroppableNode.call(this, node, map[node.attributes.id], map);
    }

    function createNodes(nodes) {
        var html = [], nodeLength = nodes.length, column = 0;
        var bugs = Prototype.Browser.IE ? 3 * this.options.colums : Prototype.Browser.Gecko ? this.options.columns : 0;
        this.columnWidth = this.options.columns > 0
            ? this.offsetWidth / this.columns - this.iconMarginX - bugs
            : this.options.columnWidth;
        var width = 'width: ' + this.columnWidth + 'px;';
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

    function changeHighlight(node) {
        var current = this.currentNodeHighlight;
        if (current) {
            var element = nodeMap[this.id][current.attributes.id].element;
            element.removeClassName('iconview_node_highlight');
            element.highlight = false;
        }
        if (node) {
            var element = nodeMap[this.id][node.attributes.id].element;
            if (element.sensitive || node.childCount != 0)
                element.addClassName('iconview_node_highlight');
            element.highlight = true;
        }
        this.currentNodeHighlight = node;
    }

    function normalizeCellAttributes() {
        for (var i = 0, l = types.length; i < l; i++) {
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
                if (Object.isFunction(klass)) {
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
                var type = this.model.columns[this.options[names[i]]].type;
                switch(type) {
                    case IWL.ListModel.DataTypes.STRING:
                        if (this.options.orientation == IWL.IconView.Orientation.HORIZONTAL)
                            cAttrs.templateRenderer = new IWL.IconView.horizontalTextRenderer();
                        else
                            cAttrs.templateRenderer = new IWL.IconView.verticalTextRenderer();
                        break;
                    case IWL.ListModel.DataTypes.IMAGE:
                        cAttrs.templateRenderer = new IWL.CellTemplateRenderer.Image();
                        break;
                }
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
            var pageContainer = new Element('div', {className: 'iconview_page_container', style: "width: " + this.offsetWidth + "px"});
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
        var icon = Element.extend(div.firstChild);
        this.iconMarginLeft = parseFloat(icon.getStyle('margin-left') || 0);
        this.iconMarginRight = parseFloat(icon.getStyle('margin-right') || 0);
        this.iconMarginTop = parseFloat(icon.getStyle('margin-top') || 0);
        this.iconMarginBottom = parseFloat(icon.getStyle('margin-bottom') || 0);
        this.iconMarginX = this.iconMarginLeft + this.iconMarginRight;
        this.iconMarginY = this.iconMarginTop + this.iconMarginBottom;
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

    function eventMouseDown(event) {
        if (nodeMap[this.id].iconSelected) {
            delete nodeMap[this.id].iconSelected;
            return;
        }
        if (nodeMap[this.id].skipIconSelect)
            return;
        if (event.ctrlKey || event.shiftKey)
            return;

        var pointer = [Event.pointerX(event), Event.pointerY(event)];
        var pos     = Element.cumulativeOffset(this);
        pointer = [pointer[0] - pos[0], pointer[1] - pos[1]];
        if (   this.offsetWidth - scrollbarSize < pointer[0]
            || this.offsetHeight - scrollbarSize < pointer[1])
            return;
        unselectAll.call(this);
    }

    function eventIconMouseDown(event, node) {
        if (this.selectedNodes.indexOf(node) > -1) {
            nodeMap[this.id].skipIconSelect = true;
            return;
        }
        toggleSelectNode.call(this, event, node);
    }

    function eventIconMouseUp(event, node) {
        if (nodeMap[this.id].skipIconSelect) {
            toggleSelectNode.call(this, event, node);
            delete nodeMap[this.id].skipIconSelect;
        }
    }

    function toggleSelectNode(event, node) {
        var first = this.selectedNodes[0];
        if (event.type == 'mousedown')
            nodeMap[this.id].iconSelected = true;
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
    }

    function unselectNode(node, skipRemoval) {
        if (!nodeMap[this.id][node.attributes.id].element.sensitive) return;
        if (!skipRemoval)
            this.selectedNodes = this.selectedNodes.without(node);
        nodeMap[this.id][node.attributes.id].element.removeClassName('iconview_node_selected');
    }

    function unselectAll() {
        for (var i = 0, l = this.selectedNodes.length; i < l; i++)
            unselectNode.call(this, this.selectedNodes[i], true);
        this.selectedNodes = [];
    }

    function boxSelectionEnd(event, draggable, coords) {
        if (! event.shiftKey && !event.ctrlKey)
            unselectAll.call(this);
        var tlCoords = coords[0];
        var brCoords = coords[1];
        if (tlCoords[0] < 1) tlCoords[0] = 1;
        if (tlCoords[1] < 1) tlCoords[1] = 1;
        var columns = [];
        for (var s = 0, i = 0; i < this.columns && s < tlCoords[0]; columns[0] = i++) {
            s += this.iconMarginLeft + this.columnWidth;
            if (tlCoords[0] < s) {
                columns[0] = i;
                break;
            }
            s += this.iconMarginRight;
        }
        for (var s = this.iconMarginLeft, i = 0; i < this.columns && s < brCoords[0]; columns[1] = i++) {
            if (brCoords[0] > s && brCoords[0] < s + this.columnWidth) {
                columns[1] = i;
                break;
            }
            s += this.columnWidth + this.iconMarginX;
        }
        
        var map = nodeMap[this.id], nodes = this.model.rootNodes, length = nodes.length, tlIndex = columns[0], tlNode;
        for (x = tlCoords[0], y = tlCoords[1]; tlIndex < length; tlIndex += this.columns) {
            var node = nodes[tlIndex];
            var element = map[node.attributes.id].element;
            var dims = [element.offsetWidth, element.offsetHeight];
            var pos = [element.offsetLeft, element.offsetTop];
            if (   x >= pos[0] - this.iconMarginX && x <= pos[0] + dims[0] + this.iconMarginX
                && y >= pos[1] - this.iconMarginY && y <= pos[1] + dims[1] + this.iconMarginY) {
                tlNode = node;
                break;
            }
        }

        if (!tlNode)
            return;

        for (y = brCoords[1]; tlIndex < length; tlIndex++) {
            var column = tlIndex % this.columns;
            if (column < columns[0] || column > columns[1])
                continue;
            var node = this.model.rootNodes[tlIndex];
            var element = map[node.attributes.id].element;
            var pos = [element.offsetLeft, element.offsetTop];

            if (y >= pos[1] - this.iconMarginY)
                selectNode.call(this, node);
            else break;
        }
    }

    function setDroppableNode(node, view, map) {
        var element = view.element, self = this;
        setTimeout(function() {
            element.setDragDest({containment: self});
            element.signalConnect('iwl:drag_hover', map.eventDragHover);
            element.signalConnect('iwl:drag_drop', map.eventDragDrop);
        }, 5);
    }

    function unsetDroppableNode(node, view, map) {
        var element = view.element;
        setTimeout(function() {
            element.unsetDragDest();
            element.signalDisconnect('iwl:drag_hover', map.eventDragHover);
            element.signalDisconnect('iwl:drag_drop', map.eventDragDrop);
        }, 5);
    }

    function eventDragDrop(event, dragElement, dropElement) {
        var dropNode = this.model.getNodeByPath(dropElement.readAttribute('iwl:nodepath').evalJSON(true)), index;
        switch(dropElement.__hoverState) {
            case hoverOverlapState.TOP:
                var pivot = dropNode.previous(this.columns - 1);
                if (pivot) index = pivot.getIndex() + 1;
                else index = 0;
                break;
            case hoverOverlapState.BOTTOM:
                var pivot = dropNode.next(this.columns - 2);
                if (pivot) index = pivot.getIndex() + 1;
                else index = -1;
                break;
            case hoverOverlapState.LEFT:
                var pivot = dropNode.previousSibling;
                if (pivot) index = pivot.getIndex() + 1;
                else index = 0;
                break;
            case hoverOverlapState.RIGHT:
                index = dropNode.getIndex() + 1;
                break;
            case hoverOverlapState.CENTER:
                index = dropNode.getIndex() + 1;
                break;
        }
        if (!isNaN(index)) {
            for (var i = this.selectedNodes.length - 1; i > -1; --i)
                this.model.move(this.selectedNodes[i], index);
        }
        unselectAll.call(this);
        setElementHoverState.call(this, dropElement, hoverOverlapState.NONE);
    }

    function eventDragHover(event, dragElement, dropElement) {
        var dropNode = this.model.getNodeByPath(dropElement.readAttribute('iwl:nodepath').evalJSON(true));
        if (this.selectedNodes.indexOf(dropNode) > -1)
            return;

        var hOverlap = Position.overlap('horizontal', dropElement);
        var vOverlap = Position.overlap('vertical', dropElement);
        var state = hoverOverlapState.NONE;
        var hCenter = vCenter = center = left = right = top = bottom = false;
        if (hOverlap < 0.3)
            state = hoverOverlapState.RIGHT;
        else if (hOverlap > 0.7)
            state = hoverOverlapState.LEFT;
        else
            hCenter = true;

        if (vOverlap < 0.3)
            state = hoverOverlapState.BOTTOM;
        else if (vOverlap > 0.7)
            state = hoverOverlapState.TOP;
        else
            vCenter = true;

        if (hCenter && vCenter)
            state = hoverOverlapState.CENTER;

        setElementHoverState.call(this, dropElement, state);
    }

    function eventDragInit(event, draggable) {
        draggable.options.view = IWL.Draggable.HTMLView;
        if (this.selectedNodes.length == 0)
            return draggable.terminateDrag();
        if (this.selectedNodes.length == 1) {
            var cellTemplate = cellTemplateRenderer.call(this, this.selectedNodes[0]);
            cellTemplate.nodeStyle = "width: " + this.columnWidth + "px;";
            draggable.options.viewOptions = {string: nodeTemplate.evaluate(cellTemplate)};
        } else if (this.selectedNodes.length > 1) {
            draggable.options.viewOptions = {string: dragMultipleIcons.evaluate({number: this.selectedNodes.length, text: 'selected icons'})};
        }

        if (this.scrollLeft || this.scrollTop) {
            Position.__includeScrollOffsets = Position.includeScrollOffsets;
            Position.includeScrollOffsets = true;
        } else if (Position.__includeScrollOffsets) {
            Position.includeScrollOffsets = Position.__includeScrollOffsets;
        }
    }

    function setElementHoverState(element, state) {
        if (this.__hoverElement && this.__hoverElement != element)
            setElementHoverState.call(this, this.__hoverElement, hoverOverlapState.NONE);

        if (element.__hoverState) {
            var className;
            switch(element.__hoverState) {
                case hoverOverlapState.TOP:
                    className = 'iconview_node_hover_top';
                    break;
                case hoverOverlapState.BOTTOM:
                    className = 'iconview_node_hover_bottom';
                    break;
                case hoverOverlapState.LEFT:
                    className = 'iconview_node_hover_left';
                    break;
                case hoverOverlapState.RIGHT:
                    className = 'iconview_node_hover_right';
                    break;
                case hoverOverlapState.CENTER:
                    className = 'iconview_node_hover_center';
                    break;
            }
            Element.removeClassName(element, className);
        }

        element.__hoverState = state;
        var className = '';
        switch(state) {
            case hoverOverlapState.TOP:
                className = 'iconview_node_hover_top';
                    break;
            case hoverOverlapState.BOTTOM:
                className = 'iconview_node_hover_bottom';
                    break;
            case hoverOverlapState.LEFT:
                className = 'iconview_node_hover_left';
                    break;
            case hoverOverlapState.RIGHT:
                className = 'iconview_node_hover_right';
                    break;
            case hoverOverlapState.CENTER:
                className = 'iconview_node_hover_center';
                    break;
            default:
                this.__hoverElement = undefined;
                return;
        }
        this.__hoverElement = element;
        Element.addClassName(element, className);
    }

    function eventIconViewHover(event) {
        if (this.__hoverElement && Event.element(event) != this.__hoverElement)
            setElementHoverState.call(this, this.__hoverElement, hoverOverlapState.NONE);
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

                normalizeCellAttributes.call(this);
                loadData.call(this, null);

                this.toggleActive.apply(this, this.options.initialActive);

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
        /**
         * Enables/Disables icon dragging for the Icon View
         * @param {Boolean} bool If true, dragging will be enabled for the Icon View
         * @returns The object
         * */
        setModelDragSource: function(bool) {
            if (this.options.dragSource == (bool = !!bool))
                return;

            this.options.dragSource = bool;
            var map = nodeMap[this.id];
            if (!map.eventDragInit)
                map.eventDragInit = eventDragInit.bind(this);

            if (bool) {
                this.setDragSource({revert: true});
                this.signalConnect('iwl:drag_init', map.eventDragInit);
            } else {
                this.unsetDragSource();
                this.signalDisconnect('iwl:drag_init', map.eventDragInit);
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
         * @returns The object
         * */
        setModelDragDest: function(bool) {
            if (this.options.dragDest == (bool = !!bool))
                return;

            this.options.dragDest = bool;
            var map = nodeMap[this.id];
            if (!map.eventDragHover)
                map.eventDragHover = eventDragHover.bind(this);
            if (!map.eventDragDrop)
                map.eventDragDrop = eventDragDrop.bind(this);
            if (!map.eventIconViewHover)
                map.eventIconViewHover = eventIconViewHover.bind(this);

            if (bool) {
                this.setDragDest({containment: this});
                this.signalConnect('iwl:drag_hover', map.eventIconViewHover);
            } else {
                this.unsetDragDest();
                this.signalDisconnect('iwl:drag_hover', map.eventIconViewHover);
            }

            for (var i = 0, l = this.model.rootNodes.length; i < l; i++) {
                var node = this.model.rootNodes[i];
                var view = map[node.attributes.id];
                bool
                    ? setDroppableNode.call(this, node, view, map)
                    : unsetDroppableNode.call(this, node, view, map);
            }
            
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
                initialActive: [],
                maxHeight: 400,
                popUpDelay: 0.2,
                boxSelectionOpacity: 0.5
            }, arguments[1]);
            if (this.options.pageControl) {
                this.pageControl = $(this.options.pageControl);
                this.pageControl.signalConnect('iwl:current_page_is_changing', pageChanging.bind(this));
                this.pageControl.signalConnect('iwl:current_page_change', pageChange.bind(this));
            }
            this.selectedNodes = [];
            this.selectedPaths = [];

            getIconMargin.call(this);
            this.columns = this.options.columns
                || parseInt((this.offsetWidth - scrollbarSize) / (this.options.columnWidth + this.iconMarginX));
            nodeMap[this.id] = {};

            if (model) {
                if (Object.keys(model.options.columnTypes).length)
                    IWL.ListModel.overrideDefaultDataTypes(model.options.columnTypes);
                if (!(model instanceof IWL.ListModel))
                    model = new (model.classType.objectize())(model);
                this.setModel(model);
            }

            this.state = 0;
            this.boxSelection = new IWL.BoxSelection(this, {boxOpacity: this.options.boxSelectionOpacity});

            if (window.attachEvent)
                window.attachEvent("onunload", function() {
                    this.model = this.pageContainer = this.boxSelection = null;
                    nodeMap[this.id] = {};
                    if (this.boxSelection)
                        this.boxSelection.destroy();
                }.bind(this));

            this.emitSignal('iwl:load');
            this.signalConnect('mousedown', eventMouseDown.bind(this));
            this.signalConnect('iwl:box_selection_end', boxSelectionEnd.bind(this));
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
IWL.IconView.horizontalTextRenderer = Class.create(IWL.CellTemplateRenderer, (function() {
    hTextTemplate = new Template('<span class="iconview_node_text iconview_node_text_horizontal">#{cellValue}</span>');
    return {
        render: function(value, node) {
            return hTextTemplate.evaluate({cellValue: value});
        }
    };
})());
IWL.IconView.verticalTextRenderer = Class.create(IWL.CellTemplateRenderer, (function() {
    vTextTemplate = new Template('<p class="iconview_node_text iconview_node_text_vertical">#{cellValue}</p>');
    return {
        render: function(value, node) {
            return vTextTemplate.evaluate({cellValue: value});
        }
    };
})());
