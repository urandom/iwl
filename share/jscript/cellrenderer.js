// vim: set autoindent shiftwidth=2 tabstop=8:
IWL.CellRenderer = Class.create((function() {
  return {
    render: function(cell, value, node) {}
  };
})());

IWL.CellTemplateRenderer = Class.create((function() {
  var editable = new Template(
    '<div class="iwl-cell-value">#{value}</div><input style="display: none" class="iwl-cell-editable" onblur="Element.hide(this); Element.show(this.previousSibling);"/>'
  );
  var cell = new Template('<div class="iwl-cell-value">#{value}</div>');
  return {
    header: new Template('<div class="iwl-header-value">#{title}</div>'),
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
              if (parent) {
                if (this.options.editable.commitChange) {
                  var columnIndex = parseInt(Element.readAttribute(element, 'iwl:modelColumnIndex'));
                  parent.node.setValues(columnIndex, en.value)
                }
                Event.emitSignal(view, 'iwl:edit_end', parent, parent.node, en.value);
              } else {
                Event.emitSignal(view, 'iwl:edit_end', en.value);
              }
            }
        });
      }
    },
    render: function(value, node, columnIndex) {
      return this.options.editable
        ? editable.evaluate({value: value.toString()})
        : cell.evaluate({value: value.toString()});
    }
  };
})());

IWL.CellTemplateRenderer.String = Class.create(IWL.CellTemplateRenderer);

IWL.CellTemplateRenderer.Int = Class.create(IWL.CellTemplateRenderer, (function() {
  var cell = new Template('<div class="iwl-cell-value iwl-cell-int">#{value}</div>');
  return {
    render: function(value, node, columnIndex) {
      return this.options.editable
        ? editable.evaluate({value: parseInt(value)})
        : cell.evaluate({value: parseInt(value)});
    }
  };
})());

IWL.CellTemplateRenderer.Float = Class.create(IWL.CellTemplateRenderer, (function() {
  var cell = new Template('<div class="iwl-cell-value iwl-cell-float">#{value}</div>');
  return {
    render: function(value, node, columnIndex) {
      return this.options.editable
        ? editable.evaluate({value: parseFloat(value)})
        : cell.evaluate({value: parseFloat(value)});
    }
  };
})());

IWL.CellTemplateRenderer.Boolean = Class.create(IWL.CellTemplateRenderer, (function() {
  var cell = new Template('<div class="iwl-cell-value iwl-cell-boolean">#{value}</div>');
  return {
    render: function(value, node, columnIndex) {
      var bool = (!!value).toString();
      return this.options.editable
        ? editable.evaluate({value: bool})
        : cell.evaluate({value: bool});
    }
  };
})());

IWL.CellTemplateRenderer.Count = Class.create(IWL.CellTemplateRenderer, (function() {
  var cell = new Template('<div class="iwl-cell-value iwl-cell-count">#{value}</div>');
  return {
    render: function(value, node, columnIndex) {
      return cell.evaluate({value: node.getIndex() + 1 + (node.model.options.offset || 0)});
    }
  };
})());

IWL.CellTemplateRenderer.Image = Class.create(IWL.CellTemplateRenderer, (function() {
  var imageTemplate = new Template('<div class="iwl-cell-value iwl-cell-image"><img class="image" src="#{src}" alt="#{alt}" /></div>');
  return {
    render: function(value, node, columnIndex) {
      return imageTemplate.evaluate(value);
    }
  };
})());

IWL.CellTemplateRenderer.Checkbox = Class.create(IWL.CellTemplateRenderer, (function() {
  var checkTemplate = new Template('<div class="iwl-cell-value iwl-cell-checkbox"><input type="checkbox" class="checkbox" #{active} name="#{name}" value="#{value}" iwl:modelColumnIndex="#{modelColumnIndex}"/></div>');
  return {
    header: new Template('<div class="iwl-header-value iwl-header-checkbox"><input type="checkbox" class="checkbox" iwl:modelColumnIndex="#{modelColumnIndex}"/></div>'),
    initialize: function() {
      this.options = Object.extend({}, arguments[0] || {});

      if (this.options.view) {
        var view = this.options.view;
        Event.delegate(view, 'change', '.iwl-header-checkbox input', function(event) {
            var element = Event.element(event),
                boxes = Element.select(view, '.iwl-cell-checkbox input'),
                checked = element.checked,
                columnIndex = parseInt(Element.readAttribute(element, 'iwl:modelColumnIndex'));
            for (var i = 0, l = boxes.length; i < l; i++) {
              boxes[i].checked = checked;
              Event.emitSignal(boxes[i], 'change', columnIndex);
            }
        });
      /* Gtk2 does not set the node value automatically. Should we?
        Event.delegate(view, 'change', '.iwl-cell-checkbox input', function(event) {
            var element = Event.element(event);
            var parent = Element.up(element, '.iwl-node');
            var columnIndex = event.memo ? event.memo[0] : parseInt(Element.readAttribute(element, 'iwl:modelColumnIndex'));
            if (parent) parent.node.setValues(columnIndex, element.checked);
        });
      */
      }
    },
    render: function(value, node, columnIndex) {
      var name = node.columns[columnIndex].name;
      return checkTemplate.evaluate({
        active: value ? 'checked="checked"' : '',
        name: name,
        value: name + '_' + node.getIndex(),
        modelColumnIndex: columnIndex
      });
    }
  };
})());
