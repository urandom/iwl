// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.Tree is a class for adding tree widgets
 * @extends IWL.Widget
 * */
IWL.Tree = Object.extend(Object.extend({}, IWL.Widget), (function () {
    var appendDelay = 0.025;
    var preloaded = false;

    function bodySort(dir, col_num) {
        this.__sorted_rows = [];
        rowSort.call(this, this.body, dir, col_num);
        timeoutAppend.bind(this).delay(appendDelay);
    }

    function rowSort(row, dir, col_num) {
        if (!col_num) col_num = 0;
        if (!dir) dir = 0;
        var children =  this.getChildRows(row, 1);
        if (!children) return;
        var sortFunc = callCustomSortables.call(this, col_num);
        children.sort(sortFunc);
        row.childList = [];
        if (dir) children.reverse();
        var alt_c_counter = 1;
        children.each(function($_) {
            this.__sorted_rows.push($_);
            row.childList.push($_);
            if (row.collapsed)
                $_.style.display = 'none';
            if ($_.isParent && $_.childList.length)
                rowSort.call(this, $_, dir, col_num);
        }.bind(this));
    }

    function callCustomSortables(col_num) {
        /* this.sortables = {col_num: [func_ref, [args]]} */
        if (!this.sortables || !this.sortables[col_num] || !this.sortables[col_num][0])
            return rowTextCompare.call(this, col_num);

        return this.sortables[col_num][0](col_num);
    }

    function rowTextCompare(col_num) {
        return function (a,b) {
            var text1 = Element.getText(a.cells[col_num]);
            var text2 = Element.getText(b.cells[col_num]);
            if (!text1 || !text2) return;
            var int1 = parseFloat(text1);
            var int2 = parseFloat(text2);
            if (int1 && int2)
                return int1 - int2;
            text1 = text1.toLowerCase();
            text2 = text2.toLowerCase();
            if (text1 < text2) {
                return -1;
            }
            if (text1 > text2) {
                return 1;
            }
            return 0;
        };
    }

    function timeoutAppend() {
        var counter = 0;
        while (this.__sorted_rows.length && counter++ < 10) {
            var row = this.__sorted_rows.shift();
            this.body.appendChild(row);
        }
        if (this.__sorted_rows.length)
            timeoutAppend.bind(this).delay(appendDelay);
        else {
            rebuildPath.call(this, this.body);
            setAlternate.call(this, this.body);
            initNavRebuild.call(this, this.body.rows.length);
        }
    }

    function initNavRebuild(totals) {
        if (!this.body || this.body.rows.length != totals) {
            initNavRebuild.bind(this, totals).delay(0.1);
            return;
        }
        createPathMap.call(this);
        if (this.isList) return;
        for (var i = 0; i < this.body.rows.length; i++)
            this.body.rows[i]._rebuildNav();
        return this;
    }

    function rebuildPath(row) {
        if (!(row = $(row)) && !(row = this.body)) return;
        for (var i = 0; i < row.childList.length; i++) {
            var child = row.childList[i];
            var path = [];
            if (row.path)
                path = row.path.clone();
            path.push(i);
            child.path = path;
            if (child.childList && child.childList.length)
                rebuildPath.call(this, child);
        }
        return this;
    }

    function createPathMap() {
        this.pathMap = {};
        this.__pathMapDelay = false;
        for (var i = 0, l = this.body.rows.length, r = this.body.rows[0]; i < l; r = this.body.rows[++i])
            this.pathMap[r.path.join()] = r;
    }

    function addToPathMap(row) {
        this.pathMap[row.path.join()] = row;
    }

    function keyEventsCB(event) {
        var keyCode = Event.getKeyCode(event);
        var row;

        if (keyCode == Event.KEY_UP)  {
            if (row = this.getPrevRow())
                row.setSelected(true);
            Event.stop(event);
        } else if (keyCode == Event.KEY_DOWN) {
            if (row = this.getNextRow())
                row.setSelected(true);
            Event.stop(event);
        } else if (keyCode == Event.KEY_RETURN) {
            if (this.currentRow)
                this.currentRow.activate();
            else
                this.body.rows[0].activate();
        }
        if (!this.isList) {
            if (keyCode == Event.KEY_LEFT) {
                if (this.currentRow)
                    this.currentRow.collapse();
                Event.stop(event);
            } else if (keyCode == Event.KEY_RIGHT) {
                if (this.currentRow)
                    this.currentRow.expand(event.shiftKey);
                Event.stop(event);
            }
        }
    }

    function setAlternate(row) {
        row = $(row);
        if (!row || !this.options.isAlternating) return;
        if (!this.body.rows.length) return;

        if (row === this.body)
            var base_class = $A(row.down().classNames()).first() + '_0';
        else
            var base_class = $A(row.classNames()).first() + '_' + (row.getLevel() + 1);

        var children = this.getChildRows(row, true);

        children.each(function($_, $i) {
            $_.removeClassName(base_class);
            $_.removeClassName(base_class + '_alt');
            if ($i % 2)
                $_.addClassName(base_class + '_alt');
            else
                $_.addClassName(base_class);

            if ($_.childList && $_.childList.length)
                setAlternate.call(this, $_);
        }.bind(this));
        return this;
    }

    return {
        /**
         * Selects the given row 
         * @param row The row to select. If none is given, the current one is used.
         * @returns The object
         * */
        selectRow: function(row) {
            if (!(row = $(row))) return;
            row.setSelected(true);
            return this;
        },
        /**
         * Unselects the given row 
         * @param row The row to unselect. If none is given, the current one is used.
         * @returns The object
         * */
        unselectRow: function(row) {
            if (!(row = $(row)) && !(row = this.currentRow)) return;
            row.setSelected(false);
            return this;
        },
        /**
         * Selects all the rows
         * @returns The object
         * */
        selectAllRows: function() {
            this.selectedRows = [];
            if (!this.options.multipleSelect) return;
            $A(this.body.rows).each(function(row) {
                row.addClassName('row_selected');
                this.selectedRows.push(row);
            }.bind(this));
            this.currentRow = this.selectedRows[this.selectedRows.length - 1];
            this.emitSignal('iwl:select_all');
            return this;
        },
        /**
         * Unselects all the rows
         * @returns The object
         * */
        unselectAllRows: function() {
            this.selectedRows.each(function(row) {
                row.removeClassName('row_selected');
            }.bind(this));
            this.currentRow = null;
            this.selectedRows = [];
            this.emitSignal('iwl:unselect_all');
            return this;
        },
        /**
         * @returns The currently selected row
         * */
        getSelectedRow: function() {
            return this.currentRow;
        },
        /**
         * @returns An array of all the selected rows
         * */
        getSelectedRows: function() {
            return this.selectedRows;
        },
        /**
         * Activates the given row
         * @param row The row to activate. If none is given, the current one is used.
         * @returns The object
         * */
        activateRow: function(row) {
            if (!(row = $(row)) && !(row = this.currentRow)) return;
            row.activate();
            return this;
        },
        /**
         * Returns the previous row
         * @param row The reference row. If none is given, the current one is used.
         * @returns The previous row
         * */
        getPrevRow: function(row) {
            var prev;
            var child;
            if (!(row = $(row)) && !(row = this.currentRow)) return;
            if (prev = this._getPrevRow(row)) {
                if (child = this.getLastChildRow(prev)) return child;
                else return prev;
            } else {
                return this.getParentRow(row);
            }
        },
        /**
         * Returns the next row
         * @param row The reference row. If none is given, the current one is used.
         * @returns The next row
         * */
        getNextRow: function(row) {
            var rec = arguments[1] || false;
            var next;
            if (!(row = $(row)) && !(row = this.currentRow)) return;
            if (!rec && (next = this.getFirstChildRow(row))) return next;
            else if (next = this._getNextRow(row)) return next;
            else {
                var parent_row = this.getParentRow(row);
                if (!parent_row) return;
                return this.getNextRow(parent_row, 1);
            }
        },
        /**
         * Returns the parent row
         * @param row The reference row. If none is given, the current one is used.
         * @returns The parent row
         * */
        getParentRow: function(row) {
            row = $(row) || this.currentRow;
            if (!row || !row.path) return;
            var path = row.path.clone();
            path.pop();
            return this.getRowByPath(path);
        },
        /**
         * Returns the first child row
         * @param row The reference row. If none is given, the current one is used.
         * @returns The child row
         * */
        getFirstChildRow: function(row) {
            row = $(row) || this.currentRow;
            if (!row || !row.isParent || row.collapsed) return;
            var path = new Array;
            return this.getChildRows(row, true)[0];
        },
        /**
         * Returns the absolute last visible child row
         * @param row The reference row. If none is given, the current one is used.
         * @returns The child row
         * */
        getLastChildRow: function(row) {
            row = $(row) || this.currentRow;
            if (!row || !row.isParent || row.collapsed) return;
            var last_child = this.getChildRows(row, true).last();
            if (last_child.isParent && !last_child.collapsed)
                return this.getLastChildRow(last_child, true);
            else return last_child;
        },
        /**
         * Returns the child rows
         * @param row The reference row. If none is given, the current one is used.
         * @param flat If true, only the immediate descendants are returned
         * @returns The child row
         * */
        getChildRows: function(row, flat) {
            row = $(row) || this.currentRow;
            if (!row || !row.childList) return;
            if (flat) return row.childList;
            var child_rows = [];
            row.childList.each(function($_) {
                child_rows.push($_);
                if ($_.childList && $_.childList.length)
                    child_rows = child_rows.concat(this.getChildRows($_));
            }.bind(this));
            return child_rows;
        },
        /**
         * Returns a row by the given path
         * @param path A path array, which describes the position of the row
         * @returns The row
         * */
        getRowByPath: function(path) {
            if (!path || typeof path.length !== 'number' || !path.length) return;
            return this.pathMap[path.join()];
        },
        /**
         * Collapses the row
         * @param row The row to collapse. If none is given, the current one is used.
         * @returns The object
         * */
        collapseRow: function(row) {
            if (!(row = $(row)) && !(row = this.currentRow)) return;
            row.collapse();
            return this;
        },
        /**
         * Expands the row
         * @param row The row to expand. If none is given, the current one is used.
         * @returns The object
         * */
        expandRow: function(row, all) {
            if (!(row = $(row)) && !(row = this.currentRow)) return;
            row.expand(all);
            return this;
        },
        /**
         * Removes the given row
         * @param row The row to remove. If none is given, the current one is used.
         * @returns The object
         * */
        removeRow: function(row) {
            if (!(row = $(row)) && !(row = this.currentRow)) return;
            var parent_row = row.parentRow() || this.body;
            var dom_parent = row.parentNode;
            var child_rows = row.childRows();
            var prev = this._getPrevRow(row) || this._getNextRow(row);
            row.setSelected(false);
            if (!prev) {
                if (parent_row !== this.body) {
                    parent_row.isParent = false;
                    parent_row.collapsed = true;
                    prev = parent_row;
                }
            } 
            if (prev) prev.setSelected(true);
            else this.unselectRow();

            dom_parent.removeChild(row);
            if (child_rows)
                child_rows.each(function(child) {
                    dom_parent.removeChild(child);
                });
            parent_row.childList = parent_row.childList.without(row);
            rebuildPath.call(this, parent_row);
            if (this.__pathMapDelay) clearTimeout(this.__pathMapDelay);
            this.__pathMapDelay = (function() {
                    createPathMap.call(this);
                    if (parent_row && parent_row._rebuildNav) parent_row._rebuildNav();
                }).bind(this).delay(0.1);
            if (prev) {
                prev._rebuildNav();
                var prev_children = prev.childRows();
                if (prev_children)
                    prev_children.invoke('_rebuildNav');
            }
            row.emitSignal('iwl:remove');
            return this;
        },
        /**
         * Appends a row, or an array of rows
         * @param parentRow The parent row for the appended row. Can be the tree body
         * @param json The row json object or HTML row string to append. It can be an array of such objects
         * @param reference A reference row. If given, the created row will be inserted before this one
         * @returns The object
         * */
        appendRow: function(parentRow, json) {
            var parentRow = $(parentRow);
            var reference = $(arguments[2]) || (parentRow == this.body ? null : this.getNextRow(parentRow));
            var all_rows = $A(this.body.rows);
            var new_rows = [];

            if (Object.isString(json) || Object.isElement(json))
                json = [json];
            else {
                if (typeof json !== 'object') return;
                if (!json.length) json = [json];
            }
            for (var i = 0; i < json.length; i++) {
                var row_data = json[i];
                if (!row_data) continue;
                var row = null;
                var row_id = 'tree_row_' + Math.random();
                if (Object.isString(row_data)) {
                    $(this.body).insert(unescape(row_data));
                    row = $A(this.body.rows).last();
                    if (reference)
                        this.body.insertBefore(row, reference);
                } else if (Object.isElement(row_data)) {
                    if (reference)
                        row = this.body.insertBefore(row_data, reference);
                    else
                        row = this.body.appendChild(row_data);
                } else {
                    row = this.body.createHtmlElement(row_data, reference);
                }
                if (!(row = $(row))) return;
                if (!row.id) row.id = row_id;
                row.addClassName($A(this.classNames()).first() + '_row');
                var old_parent = parentRow;
                if (row.hasAttribute('iwl:treeRowParent'))
                    parentRow = $(unescape(row.readAttribute('iwl:treeRowParent')));
                row.path = [0, 0];       // Fake this, so that the row won't get added to the body's childList. The path is rebuilt later
                new_rows.push(IWL.Tree.Row.create(row, this));
                if (parentRow && parentRow !== this.body && parentRow.childList) {
                    parentRow.isParent = true;
                    parentRow.childList.push(row);
                    if (parentRow.collapsed) row.hide();
                    if (row.isParent && parentRow.collapsed) row.collapsed = true;
                }
                parentRow = old_parent;
            }
            if (this.loadComplete) {
                rebuildPath.call(this, parentRow);
                setAlternate.call(this, parentRow);
                if (parentRow && parentRow !== this.body)
                    parentRow._rebuildNav();
                new_rows.each(function(row) {
                    addToPathMap.call(this, row);
                    row._rebuildNav();
                }.bind(this));
            }

            return this;
        },
        /**
         * Sorts the tree, based on the column-provided algorithm
         * @param cell The cell, which will provide the sorting algorithm
         * @param {Boolean} descending True, if the sorting will be in descending order
         * @returns The object
         * */
        sort: function(cell) {
            if (!(cell = $(cell))) return;
            if (!this.loadComplete) {
                this.sort.bind(this, cell).delay(0.5);
                return;
            }
            var row = cell.parentNode;
            var col_num = 0;
            var dir = arguments[1] != null ? arguments[1] :
                cell.readAttribute("iwl:treeCellDescSort") == 1 ? 0 : 1;
            if (!dir) dir = 0;
            for (var i = 0; i < row.cells.length; i++) {
                if (row.cells[i] == cell)
                    col_num = i;
            }

            if (!arguments[2])
            bodySort.call(this, dir, col_num);
            var icon = dir ? '/arrows_down.gif' : '/arrows_up.gif';
            if (cell.lastChild.className != 'sort_column_image') {
                if (this.sortImage)
                    this.sortImage.parentNode.removeChild
                        (this.sortImage);
                this.sortImage = new Element('img', {
                    className: 'sort_column_image',
                    src: IWL.Config.ICON_DIR + icon
                });
                cell.insertBefore(this.sortImage, cell.firstChild);
            } else {
                cell.lastChild.src = IWL.Config.ICON_DIR + icon;
            }
            cell.setAttribute("iwl:treeCellDescSort", dir);
            return this;
        },
        /**
         * Sets the custom sortable algorithm for a given column
         * @param {Number} col_num The column number, for which the sort algorighm will be assigned
         * @param descending True, if the sorting will be in descending order
         * @returns The object
         * */
        setCustomSortable: function(col_num, callback, args) {
            this.sortables[col_num] = [callback, args];
            return this;
        },

        _init: function(id, images) {
            this.body = $(this.tBodies[0]);
            this.currentRow = null;
            this.sortables = {};
            this.selectedRows = [];
            this.sortImage = null;
            this.ignoreClick = false;
            this.loadComplete = true;
            this.isList = this.hasClassName('list');
            this.options = Object.extend({
                isAlternating: false,
                multipleSelect: false,
                clickToExpand: false,
                scrollToSelection: false,
                animate: false
            }, arguments[2] || {});

            if (!this.body) return;
            this.body.isParent = true;
            this.body.collapsed = false;
            this.body.cleanWhitespace();
            this.body.childList = [];
            $A(this.body.rows).each(function($_) {
                IWL.Tree.Row.create($_, this);
            }.bind(this));
            this.navImages = {};
            for (var i in images) {
                var image = unescape(images[i]).evalJSON();
                attributes = [];
                for (var attr in image.attributes)
                    attributes.push(attr + '="' + image.attributes[attr] + '"');
                this.navImages[i] = '<img ' + attributes.join(' ') + '/>';
                if (!preloaded)
                    (new Image).src = image.attributes.src;
            }
            preloaded = true;
            this.navImages['span'] = '<span class="tree_nav_con"></span>';
            initNavRebuild.bind(this, this.body.rows.length).delay(0.1);

            this.registerFocus();
            this.keyLogger(keyEventsCB.bindAsEventListener(this));
        },
        // On the same level
        _getPrevRow: function(row) {
            if (!row || !row.path) return;
            var path = row.path.clone();
            path[path.length - 1] = path[path.length - 1] - 1;
            return this.getRowByPath(path);
        },
        // On the same level
        _getNextRow: function(row) {
            if (!row || !row.path) return;
            var path = row.path.clone();
            path[path.length - 1] = path[path.length - 1] + 1;
            return this.getRowByPath(path);
        },
        _refreshResponse: function(json, params, options) {
            if (!json.rows.length) return;
            if (this.currentRow) this.currentRow.setSelected(false);
            if (!options.append) {
                this.body.update();
                this.body.childList = [];
            }
            this.appendRow(this.body, json.rows);
        }
    }
})());

/**
 * @class IWL.Tree.Row is a class for tree rows
 * @extends IWL.Widget
 * */
IWL.Tree.Row = Object.extend(Object.extend({}, IWL.Widget), (function () {
    function initEvents() {
        this.observe('click', function(event) {
            IWL.Focus.current = this.tree;
            if (this.tree.options.multipleSelect) {
                if (event.ctrlKey) {
                    if (this.isSelected())
                        this.setSelected(false);
                    else
                        this.setSelected(true);
                } else {
                    this.tree.unselectAllRows();
                    this.setSelected(true);
                    this.tree.selectedRows = [this];
                }
            } else this.setSelected(true);

            if (this.tree.ignoreClick) {
                this.tree.ignoreClick = false;
                return;
            }
            if (this.tree.options.clickToExpand) {
                if (this.collapsed)
                    this.expand(event.shiftKey);
                else
                    this.collapse();
            }
        }.bind(this));
        this.observe('dblclick', function(event) {
            IWL.Focus.current = this.tree;
            this.activate();
        }.bind(this));
    }

    return {
        /**
         * Sets whether the row is selected
         * @param {Boolean} selected True if the row should be selected
         * @returns The object
         * */
        setSelected: function(select) {
            if (select) {
                if (this.isSelected()) return;
                if (!this.tree.options.multipleSelect && this.tree.currentRow)
                    this.tree.currentRow.setSelected(false);
                this.addClassName('row_selected');
                this.tree.currentRow = this;
                if (this.tree.options.scrollToSelection)
                    this.scrollTo();

                if (this.tree.options.multipleSelect)
                    this.tree.selectedRows.push(this);
                this.emitSignal('iwl:select');
            } else {
                if (!this.isSelected()) return;
                this.removeClassName('row_selected');
                if (this == this.tree.currentRow) {
                    this.tree.currentRow = null;
                }
                if (this.tree.options.multipleSelect)
                    this.tree.selectedRows = this.tree.selectedRows.without(this);
                this.emitSignal('iwl:unselect');
            }
            return this;
        },
        /**
         * @returns True if the row is selected
         * @type Boolean
         * */
        isSelected: function() {
            return this.hasClassName('row_selected');
        },
        /**
         * @returns True if the row is visible
         * @type Boolean
         * */
        isVisible: function() {
            if (this.tree.isList) return true;

            return this.visible();
        },
        /**
         * Activates the row
         * @returns The object
         * */
        activate: function() {
            this.tree.emitSignal('iwl:row_activate', this);
            this.emitSignal('iwl:activate');
            this._abortEvent($A(this.tree.body.rows), 'IWL-Tree-Row-activate', this);
        },
        /**
         * @returns The previous row
         * */
        prevRow: function() {
            return this.tree.getPrevRow(this);
        },
        /**
         * @returns The next row
         * */
        nextRow: function() {
            return this.tree.getNextRow(this);
        },
        /**
         * @returns The parent row
         * */
        parentRow: function() {
            return this.tree.getParentRow(this);
        },
        /**
         * @returns The first child row
         * */
        firstChildRow: function() {
            return this.tree.getFirstChildRow(this);
        },
        /**
         * @returns The absolute last visible child row
         * */
        lastChildRow: function() {
            return this.tree.getLastChildRow(this);
        },
        /**
         * Returns the child rows
         * @param flat If true, only the immediate descendants are returned
         * @returns The child row
         * */
        childRows: function(flat) {
            return this.tree.getChildRows(this, flat);
        },
        /**
         * Collapses the row
         * @returns The object
         * */
        collapse: function() {
            if (this.tree.isList || this.collapsed) return;
            var child_rows = this.childRows(true);
            if (!child_rows.length) return;
            child_rows.each(function(child) {
                if (child.tree.options.animate)
                    new Effect.SlideUp(child, {duration: 0.5});
                else
                    child.hide();
                if (child.isParent)
                    child.collapse();
            });
            this.collapsed = true;
            this._rebuildNav();
            this.emitSignal('iwl:collapse');
            this.tree.emitSignal('iwl:row_collapse', this);
            return this;
        },
        /**
         * Expands the row
         * @returns The object
         * */
        expand: function() {
            if (this.tree.isList || !this.collapsed) return;
            var child_rows = this.childRows(true);
            if (child_rows.length) {
                var all = arguments[0];
                child_rows.each(function(child) {
                    child.show();
                    if (all && child.isParent)
                        child.expand(all);
                    else child._rebuildNav();
                });
                this.collapsed = false;
                this._rebuildNav();
                this.emitSignal('iwl:expand');
                this.tree.emitSignal('iwl:row_expand', this);
            } else {
                if (this._expanding) return;
                this._expanding = true;
                var params = {}, options = {};
                if (Object.isObject(arguments[0])) {
                    params = Object.extend({}, arguments[0]);
                    options = Object.isObject(arguments[1])
                        ? Object.extend({}, arguments[1]) : {all: arguments[1]};
                } else {
                    options = {all: arguments[0]};
                }
                this.emitEvent('IWL-Tree-Row-expand', params, options);
            }
            return this;
        },
        /**
         * Removes the row
         * @returns The object
         * */
        remove: function() {
            this.tree.removeRow(this);
            return this;
        },
        /**
         * Appends a row, or an array of rows, as children to this row
         * @param json The row json object or HTML row string to append. It can be an array of such objects
         * @param reference A reference row. If given, the created row will be inserted before this one
         * @returns The object
         * */
        append: function(json) {
            this.tree.appendRow(this, json, arguments[1]);
            return this;
        },
        /**
         * @returns The row level
         * */
        getLevel: function() {
            if (this.tree.isList) 0;
            return this.path.length - 1;
        },

        _init: function(id, tree) {
            this.tree = tree;
            this.childList = [];

            var row_data = unescape(this.readAttribute('iwl:treeRowData') || '{}').evalJSON();
            if (row_data.childList && row_data.childList.length)
                row_data.childList = row_data.childList.map(function($_) {
                    return $($_);
                }).compact();
            Object.extend(this, row_data);
            if (!(this.path) || !this.path.length || this.path.length == 1 || this.tree.isList)
                this.tree.body.childList.push(this);
            initEvents.call(this);
        },
        _rebuildNav: function() {
            if (!this.tree.navImages) return;
            if (this.tree.isList) return;
            if (!this.isVisible()) return;
            var id = this.id + '_nav';
            var indent = [];
            var type = [];

            var nav = $(this.id + '_nav_con');
            if (!nav) {
                var cell = this.firstChild;
                if (!cell) {
                    this.insert("<td>");
                    cell = this.firstChild;
                }
                $(cell).insert({top: this.tree.navImages.span});
                nav = cell.firstChild;
                nav.id = this.id + '_nav_con';
            }
            nav.innerHTML = '';

            // Indent
            if (this.path.length > 1) {
                var path = new Array;
                for (var i = 0; i < this.path.length - 1; i++) {
                    path.push(this.path[i]);
                    var paren = this.tree.getRowByPath(path);
                    if (paren && !this.tree._getNextRow(paren))
                        indent.push(this.tree.navImages.b);
                    else
                        indent.push(this.tree.navImages.i);
                    type.push(false);
                }
            }
            // Nav
            if (this.tree._getNextRow(this)) {
                if (this.isParent) {
                    if (this.collapsed) {
                        indent.push(this.tree.navImages.t_e);
                        type.push('expand');
                    } else {
                        indent.push(this.tree.navImages.t_c);
                        type.push('collapse');
                    }
                } else {
                    indent.push(this.tree.navImages.t);
                    type.push(false);
                }
            } else {
                var prev = this.tree._getPrevRow(this);
                if (prev) prev._rebuildNav();		// Rebuilds the previous row, in case this one was added after the initial rebuild
                if (this.isParent) {
                    if (this.collapsed) {
                        indent.push(this.tree.navImages.l_e);
                        type.push('expand');
                    } else {
                        indent.push(this.tree.navImages.l_c);
                        type.push('collapse');
                    }
                } else {
                    indent.push(this.tree.navImages.l);
                    type.push(false);
                }
            }
            nav.innerHTML = indent.join('');
            Element.cleanWhitespace(nav);
            var children = nav.childNodes;
            for (var i = 0, c = children[0], l = children.length; i < l; c = children[++i]) {
                if (!type[i]) continue;
                else if (type[i] == 'expand')
                    Event.observe(c, "click", function (event) {
                        Event.stop(event);
                        this.expand(event.shiftKey);}.bind(this));
                else if (type[i] == 'collapse')
                    Event.observe(c, "click", function (event) {
                        Event.stop(event);
                        this.collapse();}.bind(this));
            }
        },
        _expandResponse: function(json, params, options) {
            if (json && json.length != 0) {
                this.append(json);
                this.expand(options.all);
            }
            this._expanding = false;
        }
    }
})());

/* Deprecated */
var Tree = IWL.Tree;
var Row = IWL.Tree.Row;
