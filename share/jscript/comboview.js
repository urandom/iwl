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

    function setContent() {
        this.content.update(generateNodeTemplate.call(this, true).evaluate({}));
    }

    function generateNodeTemplate(flat) {
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
            node.push('<td class="', classNames.join(' '), width, '">#{column', i, '}</td>');
        }
        if (!flat)
            node.push('<td class="comboview_parental_arrow">#{parentalArrow}</td>');
        node.push('</tr></tbody></table>');

        return new Template(node.join(''));
    }

    function onDataLoad(event, options) {
        var flat = this.model.isFlat();
        var template = generateNodeTemplate.call(this, flat)
        createNodes.call(this, this.model.getRootNodes(), template, flat);
        this.container.select('.comboview_node').each(function(node) {
            node.observe('mouseover', node.addClassName.bind(node, 'comboview_node_highlight'));
            node.observe('mouseout', node.removeClassName.bind(node, 'comboview_node_highlight'));
        });
    }

    function cellRenderer(values) {
        var renderers = {};
        for (var i = 0, l = values.length; i < l; i++) {
            var render = this.options.cellAttributes[i] && this.options.cellAttributes[i].renderTemplate;
            if (render) {
                render = new Template(render);
                renderers['column' + i] = Object.isObject(values[i])
                    ? render.evaluate(values[i])
                    : render.evaluate({cellValue: values[i]});
            } else {
                if (this.model.getColumnType(i) == IWL.TreeModel.DataTypes.STRING)
                    renderers['column' + i] = values[i].toString();
                else if (this.model.getColumnType(i) == IWL.TreeModel.DataTypes.INT)
                    renderers['column' + i] = parseInt(values[i])
                else if (this.model.getColumnType(i) == IWL.TreeModel.DataTypes.FLOAT)
                    renderers['column' + i] = parseFloat(values[i])
                else if (this.model.getColumnType(i) == IWL.TreeModel.DataTypes.BOOLEAN)
                    renderers['column' + i] = values[i].toString();
                else if (this.model.getColumnType(i) == IWL.TreeModel.DataTypes.CHECKBOX)
                    renderers['column' + i] = '<input type="checkbox" value="' + values[i] + '"/>';
                else if (this.model.getColumnType(i) == IWL.TreeModel.DataTypes.RADIO)
                    renderers['column' + i] = '<input type="radio" value="' + values[i] + '" name="comboview_radio_group"/>';
                else if (this.model.getColumnType(i) == IWL.TreeModel.DataTypes.COUNT) {
                    var count = 0;
                    this.model.each(function(n) { count++; if (n == node) throw $break; });
                    renderers['column' + i] = count;
                }
            }
        }
        return renderers;
    }

    function createNodes(nodes, template, flat) {
        var html = [];
        var container = new Element('div', {className: 'comboview_node_container'});
        nodes[0] && nodes[0].parentNode
            ? nodes[0].parentNode.viewContainer = container
            : this.container = container;
        var index = 0, length = nodes.length;
        nodes.each(function(node) {
            var values = node.getValues();
            var renderers = cellRenderer.call(this, values);
            if (!flat && node.hasChildren() > 0)
                renderers.parentalArrow = '>';
            if (index == 0)
                renderers.nodePosition = 'comboview_node_first'
            else if (index + 1 == length)
                renderers.nodePosition = 'comboview_node_last'
            renderers.nodePath = node.getPath().toJSON();
            html.push(template.evaluate(renderers));
            ++index;
        }.bind(this));
        container.update(html.join(''));
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
        if (container == this.container) {
            var diff = this.getWidth() - container.getWidth() - scrollbar;
            if (diff > 0) scrollbar += diff;
            else if (diff < 0) {
                var cell = this.button.up();
                cell.setStyle({width: parseFloat(cell.getStyle('width')) - diff + 'px'});
            }
        }
        var new_width = parseInt(width) + scrollbar;
        container.addClassName('scrolling_menu');
        if (Prototype.Browser.Opera)
            container.setStyle({width: new_width + 'px', height: this.options.maxHeight + 'px', overflow: 'auto'});
        else
            container.setStyle({width: new_width + 'px', height: this.options.maxHeight + 'px', overflowY: 'scroll'});
    }


    function popUp() {
        if (this.container.popped) return;
        this.container.setStyle({display: 'block', visibility: 'hidden'});
        this.container.popped = true;
        if (!Object.isElement(this.container.parentNode))
            this.insert({after: this.container});

        if (!this.container.positioned) {
            var parent_position = this.getStyle('position') == 'absolute'
                ? this.cumulativeOffset()
                : this.positionedOffset();
            this.container.setStyle({
                left: parent_position[0] + 'px',
                top: parent_position[1] + this.getHeight() + 'px'
            });

            var table = this.container.down();
            this.container.style.width = table.getWidth()
                + parseFloat(table.getStyle('margin-left') || 0)
                + parseFloat(table.getStyle('margin-right') || 0) + 'px';
            if (this.options.maxHeight)
                setupScrolling.call(this, this.container);

            this.container.positioned = true;
            document.observe('click', function(event) {
                var inside = Event.checkElement(event, this.container);
                if (!inside && !Event.checkElement(event, this))
                    return this.popDown();
                else if (inside) {
                    var path = Event.element(event).up('table.comboview_node').readAttribute('iwl:nodePath').evalJSON();
                    this.setActive(path);
                    return this.popDown();
                }
            }.bind(this));
        }
        this.container.setStyle({visibility: 'visible'});
    }

    function popDown() {
        if (!this.container.popped) return;
        this.container.style.display = 'none';
        this.container.popped = false;
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
            this.selectedpath = path;
            if (!Object.isArray(path)) path = [path];
            var node = this.model.getNodeByPath(path);
            if (!node) return;
            this.values = node.getValues();
            var renderers = cellRenderer.call(this, this.values);
            this.content.update(generateNodeTemplate.call(this, true).evaluate(renderers));

            return this;
        },

        _init: function(id, model) {
            this.options = Object.extend({
                columnWidth: [],
                columnClass: [],
                cellAttributes: [],
                maxHeight: 400
            }, arguments[2]);
            this.model = model;
            this.button = this.down('.comboview_button');
            this.content = this.down('.comboview_content');
            this.contentColumns = [];

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
