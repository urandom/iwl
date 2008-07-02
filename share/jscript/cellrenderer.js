// vim: set autoindent shiftwidth=2 tabstop=8:
IWL.CellRenderer = Class.create((function() {
  return {
    render: function(cell, value, node) {}
  };
})());

IWL.CellTemplateRenderer = Class.create((function() {
  var editable = new Template(
    '<p class="iwl-cell-value">#{value}</p><input style="display: none" class="iwl-cell-editable" onblur="Element.hide(this); Element.show(this.previousSibling);"/>'
  );
  return {
    header: new Template("#{title}"),
    initialize: function() {
      this.options = Object.extend({}, arguments[0] || {});

      if (this.options.editable && this.options.view) {
        var view = this.options.view;
        Event.delegate(view, 'click', '.iwl-cell-value', function(event) {
            var va = Event.element(event),
                en = va.nextSibling;
            en.value = Element.getText(va);
            Element.show(en);
            Element.hide(va);
            en.focus();
            en.select();
            view._focusedElement = en;
            var parent = Element.up(en, '.iwl-node');
            parent
              ? Event.emitSignal(view, 'iwl:edit_begin', parent, parent.node, en.value)
              : Event.emitSignal(view, 'iwl:edit_begin', en.value);
        });
        Event.delegate(view, 'keypress', '.iwl-cell-editable', function(event) {
            if (event.keyCode != Event.KEY_ESC && event.keyCode != Event.KEY_RETURN) return;
            var en = Event.element(event),
                va = en.previousSibling;
            if (event.keyCode == Event.KEY_RETURN)
              va.innerHTML = en.value;
            Element.hide(en);
            Element.show(va);
            if (event.keyCode == Event.KEY_RETURN) {
              var parent = Element.up(en, '.iwl-node');
              parent
                ? Event.emitSignal(view, 'iwl:edit_end', parent, parent.node, en.value)
                : Event.emitSignal(view, 'iwl:edit_end', en.value);
            }
        });
      }
    },
    render: function(value, node, columnIndex) {
      return this.options.editable
        ? editable.evaluate({value: value.toString()})
        : value.toString();
    }
  };
})());

IWL.CellTemplateRenderer.String = Class.create(IWL.CellTemplateRenderer);

IWL.CellTemplateRenderer.Int = Class.create(IWL.CellTemplateRenderer, (function() {
  return {
    render: function(value, node, columnIndex) {
      return this.options.editable
        ? editable.evaluate({value: parseInt(value)})
        : parseInt(value);
    }
  };
})());

IWL.CellTemplateRenderer.Float = Class.create(IWL.CellTemplateRenderer, (function() {
  return {
    render: function(value, node, columnIndex) {
      return this.options.editable
        ? editable.evaluate({value: parseFloat(value)})
        : parseFloat(value);
    }
  };
})());

IWL.CellTemplateRenderer.Boolean = Class.create(IWL.CellTemplateRenderer, (function() {
  return {
    render: function(value, node, columnIndex) {
      var bool = (!!value).toString();
      return this.options.editable
        ? editable.evaluate({value: bool})
        : bool;
    }
  };
})());

IWL.CellTemplateRenderer.Count = Class.create(IWL.CellTemplateRenderer, (function() {
  return {
    render: function(value, node, columnIndex) {
      return node.getIndex() + 1 + (node.model.options.offset || 0);
    }
  };
})());

IWL.CellTemplateRenderer.Image = Class.create(IWL.CellTemplateRenderer, (function() {
  var imageTemplate = new Template('<img class="iwl-cell-image" src="#{src}" alt="#{alt}" />');
  return {
    render: function(value, node, columnIndex) {
      return imageTemplate.evaluate(value);
    }
  };
})());

IWL.CellTemplateRenderer.Checkbox = Class.create(IWL.CellTemplateRenderer, (function() {
  var checkTemplate = new Template('<input type="checkbox" class="iwl-cell-checkbox" #{active} name="#{name}" value="#{value}"/>');
  return {
    header: new Template('<input type="checkbox" class="iwl-header-checkbox" iwl:modelColumnIndex="#{modelColumnIndex}"/>'),
    initialize: function() {
      this.options = Object.extend({}, arguments[0] || {});

      if (this.options.view) {
        var view = this.options.view;
        Event.delegate(view, 'change', '.iwl-header-checkbox', function(event) {
            var element = Event.element(event),
                boxes = Element.select(view, '.iwl-cell-checkbox'),
                checked = element.checked,
                columnIndex = parseInt(Element.readAttribute(element, 'iwl:modelColumnIndex'));
            for (var i = 0, l = boxes.length; i < l; i++) {
              boxes[i].checked = checked;
              Event.emitSignal(boxes[i], 'change', columnIndex);
            }
        });
        Event.delegate(view, 'change', '.iwl-cell-checkbox', function(event, columnIndex) {
            var element = Event.element(event);
            var parent = Element.up(element, '.iwl-node');
            if (parent) parent.node.setValues(columnIndex, element.checked);
        });
      }
    },
    render: function(value, node, columnIndex) {
      var name = node.columns[columnIndex].name;
      return checkTemplate.evaluate({
        active: value ? 'checked="checked"' : '',
        name: name,
        value: name + '_' + node.getIndex()
      });
    }
  };
})());
