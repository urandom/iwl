var Calendar = {};
Object.extend(Object.extend(Calendar, Widget), (function() {
    var weeks_in_month = 6;

    function fillMonth() {
        var start_day = this.options.startOnMonday ? 1 : 0;
        var year = this.date.getFullYear();
        var month = this.date.getMonth();
        var heading_cells = this.getElementsBySelector('.calendar_heading')[0].cells;
        var week_days = this.getElementsBySelector('.calendar_week_days')[0];
        var date = this.getDate();

        date.setFullYear(year);
        date.setMonth(month);
        date.setDate(1);

        $(heading_cells[1]).down().value = Calendar.months[month];
        $(heading_cells[4]).down().value = year;

        while (date.getDay() != start_day)
            date.decrementDate();

        if (this._startDayChanged) {
            if (start_day == 0) {
                Element.extend(week_days.cells[1]).update(Calendar.shortWeekDays[6]).addClassName('calendar_weekend_header');
                for (day = 0; day < 6; day++) {
                    var cell = Element.extend(week_days.cells[day + 2]);
                    cell.innerHTML = Calendar.shortWeekDays[day];
                    if (day == 5)
                        cell.addClassName('calendar_weekend_header');
                    else
                        cell.removeClassName('calendar_weekend_header');
                }
            } else {
                for (day = 0; day < 7; day++) {
                    var cell = Element.extend(week_days.cells[day + 1]);
                    cell.innerHTML = Calendar.shortWeekDays[day];
                    if (day == 5 || day == 6)
                        cell.addClassName('calendar_weekend_header');
                    else
                        cell.removeClassName('calendar_weekend_header');
                }
            }

            this._startDayChanged = false;
        }

        var week_rows = this.getElementsBySelector('.calendar_week');
        for (week = 0; week < weeks_in_month; week++) {
            var row = week_rows[week];
            Element.extend(row.cells[0]).innerHTML = date.getWeek();

            for (day = 0; day < 7; day++) {
                var cell = Element.extend(row.cells[day + 1]);
                var this_month = date.getMonth();
                var this_year = date.getFullYear();

                if (day == 0 && !this.options.showAdjacentMonths
                        && (this_year > year || (this_month > month && this_year == year))) {
                    row.hide();
                    break;
                }

                if (!row.visible()) row.show();
                if (this.options.showAdjacentMonths) {
                    if (this_month != month)
                        cell.addClassName('calendar_week_day_disabled');
                    else
                        cell.removeClassName('calendar_week_day_disabled');
                    cell.innerHTML = date.getDate();
                } else {
                    if (this_month == month)
                        cell.innerHTML = date.getDate();
                    else cell.innerHTML = '';
                }

                if ([0,6].include(date.getDay()))
                    cell.addClassName('calendar_weekend');
                else
                    cell.removeClassName('calendar_weekend');

                cell.date = new Date(date.getTime());
                date.incrementDate();
            }
        }
        showSpecialDates.call(this);
    }

    function fillTime() {
        var hours = this.getElementsBySelector('.calendar_hours')[0];
        var minutes = this.getElementsBySelector('.calendar_minutes')[0];
        var seconds = this.getElementsBySelector('.calendar_seconds')[0];
        var notation = this.getElementsBySelector('.calendar_hours_notation')[0];

        var hour = this.date.getHours();
        if (!this.options.astronomicalTime) {
            var pm = hour >= 12;
            hour = pm ? hour - 12 : hour;
            hour = hour == 0 ? 12 : hour;
            notation.innerHTML = pm ? 'PM' : 'AM';
        } else {
            notation.innerHTML = '';
        }
        hours.value = hour;
        minutes.value = this.date.getMinutes();
        seconds.value = this.date.getSeconds();
    }

    function selectDate() {
        var cell = this.getByDate(this.date);
        cell.setSelected(true);
    }

    function connectHeadingSignals() {
        var heading_cells = this.getElementsBySelector('.calendar_heading')[0].cells;
        var prev_month = previousMonthEvent.bindAsEventListener(this);
        var next_month = nextMonthEvent.bindAsEventListener(this);
        var prev_year = previousYearEvent.bindAsEventListener(this);
        var next_year = nextYearEvent.bindAsEventListener(this);

        var month = $(heading_cells[1]).down();
        var month_focus = monthFocusEvent.bindAsEventListener(this);
        var month_blur = monthBlurEvent.bindAsEventListener(this);
        var month_key = monthKeyEvent.bindAsEventListener(this);

        var year = $(heading_cells[4]).down();
        var year_focus = yearFocusEvent.bindAsEventListener(this);
        var year_blur = yearBlurEvent.bindAsEventListener(this);
        var year_key = yearKeyEvent.bindAsEventListener(this);

        $(heading_cells[0]).signalConnect('click', prev_month);
        $(heading_cells[2]).signalConnect('click', next_month);
        $(heading_cells[3]).signalConnect('click', prev_year);
        $(heading_cells[5]).signalConnect('click', next_year);

        month.signalConnect('blur', month_blur);
        month.signalConnect('focus', month_focus);
        month.signalConnect('keypress', month_key);

        year.signalConnect('blur', year_blur);
        year.signalConnect('focus', year_focus);
        year.signalConnect('keypress', year_key);
    }

    function previousMonthEvent() {
        this.setDate(this.getDate().decrementMonth());
    }
    function nextMonthEvent() {
        this.setDate(this.getDate().incrementMonth());
    }
    function previousYearEvent() {
        this.setDate(this.getDate().decrementYear());
    }
    function nextYearEvent() {
        this.setDate(this.getDate().incrementYear());
    }

    function monthFocusEvent(event) {
        var element = event.element();
        element.value = this.date.getMonth() + 1;
        element.addClassName('calendar_month_selected');
    }
    function monthKeyEvent(event) {
        var input = event.element();

        if (Event.getKeyCode(event) == Event.KEY_RETURN) {
            var date = this.getDate();
            date.setMonth(input.value - 1);
            input.blur();
            this.emitSignal("change_month", date);
            this.setDate(date);
        }
    }
    function monthBlurEvent(event) {
        var element = event.element();
        element.value = Calendar.months[this.date.getMonth()];
        element.removeClassName('calendar_month_selected');
    }

    function yearFocusEvent(event) {
        var element = event.element();
        element.addClassName('calendar_year_selected');
    }
    function yearKeyEvent(event) {
        var input = event.element();

        if (Event.getKeyCode(event) == Event.KEY_RETURN) {
            var date = this.getDate();
            date.setFullYear(input.value);
            input.blur();
            this.emitSignal("change_year", date);
            this.setDate(date);
        }
    }
    function yearBlurEvent(event) {
        var element = event.element();
        element.value = this.date.getFullYear();
        element.removeClassName('calendar_year_selected');
    }

    function connectTimeSignals(event) {
        var hours = this.getElementsBySelector('.calendar_hours')[0];
        var minutes = this.getElementsBySelector('.calendar_minutes')[0];
        var seconds = this.getElementsBySelector('.calendar_seconds')[0];
        var notation = this.getElementsBySelector('.calendar_hours_notation')[0];

        var hours_focus = hoursFocusEvent.bindAsEventListener(this);
        var hours_key = hoursKeyEvent.bindAsEventListener(this);
        var hours_blur = hoursBlurEvent.bindAsEventListener(this);

        var minutes_focus = minutesFocusEvent.bindAsEventListener(this);
        var minutes_key = minutesKeyEvent.bindAsEventListener(this);
        var minutes_blur = minutesBlurEvent.bindAsEventListener(this);

        var seconds_focus = secondsFocusEvent.bindAsEventListener(this);
        var seconds_key = secondsKeyEvent.bindAsEventListener(this);
        var seconds_blur = secondsBlurEvent.bindAsEventListener(this);

        var notation_click = notationClickEvent.bindAsEventListener(this);

        hours.signalConnect('focus', hours_focus);
        hours.signalConnect('keypress', hours_key);
        hours.signalConnect('blur', hours_blur);

        minutes.signalConnect('focus', minutes_focus);
        minutes.signalConnect('keypress', minutes_key);
        minutes.signalConnect('blur', minutes_blur);

        seconds.signalConnect('focus', seconds_focus);
        seconds.signalConnect('keypress', seconds_key);
        seconds.signalConnect('blur', seconds_blur);

        notation.signalConnect('click', notation_click);
    }

    function hoursFocusEvent(event) {
        var element = event.element();
        element.addClassName('calendar_time_selected');
    }
    function hoursKeyEvent(event) {
        var input = event.element();

        if (Event.getKeyCode(event) == Event.KEY_RETURN) {
            var date = this.getDate();
            var hours = parseInt(input.value);
            if (hours < 13 && !this.options.astronomicalTime) {
                hours = hours == 12 ? 0 : hours;
                hours = date.getHours() > 12 ? hours + 12 : hours;
            }
            date.setHours(hours);
            input.blur();
            this.setDate(date);
        }
    }
    function hoursBlurEvent(event) {
        var element = event.element();
        var hours = this.date.getHours();
        if (!this.options.astronomicalTime) {
            hours = hours >= 12 ? hours - 12 : hours;
            hours = hours == 0 ? 12 : hours;
        }
        element.value = hours;
        element.removeClassName('calendar_time_selected');
    }

    function minutesFocusEvent(event) {
        var element = event.element();
        element.addClassName('calendar_time_selected');
    }
    function minutesKeyEvent(event) {
        var input = event.element();

        if (Event.getKeyCode(event) == Event.KEY_RETURN) {
            var date = this.getDate();
            var minutes = parseInt(input.value);
            date.setMinutes(minutes);
            input.blur();
            this.setDate(date);
        }
    }
    function minutesBlurEvent(event) {
        var element = event.element();
        element.value = this.date.getMinutes();
        element.removeClassName('calendar_time_selected');
    }

    function secondsFocusEvent(event) {
        var element = event.element();
        element.addClassName('calendar_time_selected');
    }
    function secondsKeyEvent(event) {
        var input = event.element();

        if (Event.getKeyCode(event) == Event.KEY_RETURN) {
            var date = this.getDate();
            var seconds = parseInt(input.value);
            date.setSeconds(seconds);
            input.blur();
            this.setDate(date);
        }
    }
    function secondsBlurEvent(event) {
        var element = event.element();
        element.value = this.date.getSeconds();
        element.removeClassName('calendar_time_selected');
    }


    function notationClickEvent(event) {
        var element = event.element();
        var date = this.getDate();
        var hours = date.getHours();
        var pm = hours >= 12;

        date.setHours(pm ? hours - 12 : hours + 12);
        this.setDate(date);
    }

    function keyEventsCB(event) {
        var key_code = Event.getKeyCode(event);
        var shift = event.shiftKey;
        var ctrl = event.ctrlKey;
        var cell;
        var date = this.getDate();
        var change = false;
        var date_index = this.dateCells.indexOf(this.currentDate);
        if (focused_widget != this.id)
            return;

        if (ctrl) {
            if (key_code == Event.KEY_LEFT) {
                date.decrementMonth();
                change = true;
            } else if (key_code == Event.KEY_UP)  {
                date.incrementYear();
                change = true;
            } else if (key_code == Event.KEY_RIGHT) {
                date.incrementMonth();
                change = true;
            } else if (key_code == Event.KEY_DOWN) {
                date.decrementYear();
                change = true;
            }
        } else {
            if (key_code == Event.KEY_LEFT) {
                cell = this.dateCells[date_index - 1];
            } else if (key_code == Event.KEY_UP)  {
                cell = this.dateCells[date_index - 7];
            } else if (key_code == Event.KEY_RIGHT) {
                cell = this.dateCells[date_index + 1];
            } else if (key_code == Event.KEY_DOWN) {
                cell = this.dateCells[date_index + 7];
            } else if (key_code == Event.KEY_RETURN) {
                if (this.currentDate)
                    this.currentDate.activate();
            } else if (key_code == Event.KEY_ESC) {
                this.setDate(new Date);
            }
        }

        if (cell) {
            var cell_date = cell.getDate();

            if (!cell_date || !this.options.showAdjacentMonths
                && cell_date.getMonth() != this.date.getMonth())
                return;

            Event.stop(event);
            this.setDate(cell.getDate());
        } else if (change) {
            Event.stop(event);
            this.setDate(date);
        }
    }

    function updateElement(element, format, date) {
        if (!(date instanceof Date))
            date = this.getDate();
        if ("value" in element) {
            element.value = date.sprintf(format);
            if (typeof element.onchange == 'function')
                element.onchange.call(element);
            element.emitSignal('change');
        } else {
            element.innerHTML = date.sprintf(format);
        }
    }

    function changeDate(old_date, date) {
        if (this.date.getFullYear() == date.getFullYear() &&
            this.date.getMonth() == date.getMonth() &&
            this.date.getDate() == date.getDate())
            return false;

        if ((this.options.fromYear && (
                date.getFullYear() < this.options.fromYear 
                || (date.getFullYear() == this.options.fromYear
                    && date.getMonth() < this.options.fromMonth)
            )) || (this.options.toYear && (
                    (date.getFullYear() == this.options.toYear
                    && date.getMonth() > this.options.toMonth)
                || date.getFullYear() > this.options.toYear
            )))
            return false;

        if (this.currentDate)
            this.currentDate.setSelected(false);

        return true;
    }

    function changeTime(old_date, date) {
        if (old_date.getHours () == date.getHours()
            && old_date.getMinutes() == date.getMinutes()
            && old_date.getSeconds() == date.getSeconds())
            return false;

        return true;
    }

    function showSpecialDates() {
        if (!this.options.specialDates.length) {
            this.getElementsBySelector('.calendar_week_day_special').each(function(d) {
                d.removeClassName('calendar_week_day_special');
                d.removeClassName('calendar_week_day_special_disabled');
            });
            return;
        }
        this.dateCells.each(function (d) {
            var date = {year: d.date.getFullYear(), month: d.date.getMonth(), date: d.date.getDate()};
            var ok = false;
            for (var i = 0, s = this.options.specialDates[i];
                i < this.options.specialDates.length; s = this.options.specialDates[++i]) {
                if ((!s.year || s.year == date.year)
                    && (!s.month || s.month == date.month)
                    && (s.date == date.date)) {
                    d.addClassName('calendar_week_day_special');
                    if (d.hasClassName('calendar_week_day_disabled'))
                        d.addClassName('calendar_week_day_special_disabled');
                    ok = true;
                }
            }
            if (!ok) {
                d.removeClassName('calendar_week_day_special');
                d.removeClassName('calendar_week_day_special_disabled');
            }
        }.bind(this));
    }

    Object.extend(Date.prototype, {
        sprintf: function(string) {
            var reg = /%./g;
            var day = this.getDay();
            var date = this.getDate();
            var month = this.getMonth();
            var year = this.getFullYear();
            var syear = year.toString().substring(2);
            var day_of_year = this.getDayOfYear();
            var week = this.getWeek();

            var hour = this.getHours();
            var pm = hour >= 12;
            var pmhour = pm ? hour - 12 : hour;
            var minute = this.getMinutes();
            var seconds = this.getSeconds();
            var time_string = this.toString();
            var zone_name = this.getTimezoneName();

            pmhour = pmhour == 0 ? 12 : pmhour;

            var format = {
                a: Calendar.shortWeekDays[day],
                A: Calendar.weekDays[day],
                b: Calendar.shortMonths[month],
                B: Calendar.months[month],
                C: this.getCentury(),
                d: date < 10 ? '0' + date : date,
                D: month + '/' + date + '/' + syear,
                e: date < 10 ? ' ' + date : date,
                F: year + '-' + month + '-' + date,
                h: Calendar.shortMonths[month],
                H: hour < 10 ? '0' + hour : hour,
                I: pmhour < 10 ? '0' + pmhour : pmhour,
                j: day_of_year < 10 ? '00' + day_of_year : day_of_year < 100 ? '0' + day_of_year : day_of_year,
                k: hour,
                l: pmhour,
                m: month < 10 ? '0' + month : month,
                M: minute < 10 ? '0' + minute : minute,
                n: '\n',
                p: pm ? 'PM' : 'AM',
                P: pm ? 'pm' : 'am',
                s: this.getTime(),
                S: seconds < 10 ? '0' + seconds : seconds,
                t: '\t',
                u: day + 1,
                U: week < 10 ? '0' + week : week,
                w: day,
                y: syear,
                Y: year,
                z: this.getTimezoneOffset() / 60,
                Z: zone_name,
                '+': time_string,
                '%': '%'
            };
            format.r = format.I + ':' + format.M + ':' + format.S + ' ' + format.p;
            format.R = format.H + ':' + format.M;
            format.T = format.H + ':' + format.M + ':' + format.S;

            if (Prototype.Browser.KTHML) {
                var match;
                if (match = string.match(reg)) {
                    match.each(function(m) {
                        var replacer = format[m.substring(1)];
                        var reg1 = new RegExp(m, 'g');
                        if (replacer)
                            string = string.replace(reg1, replacer);
                    });
                }
                return string;
            }

            return string.replace(reg, function(match) {
                return format[match.substring(1)] || match;
            });
        }
    });

    return {
        setDate: function(date) {
            if (date instanceof Date && !isNaN(date.valueOf())) {
                var old_date = this.date;
                var change_date = changeDate.call(this, old_date, date);
                var change_time = changeTime.call(this, old_date, date);

                if (change_date || change_time) {
                    this.date = date;
                    if (change_date) {
                        if (old_date.getFullYear() != date.getFullYear()
                            || old_date.getMonth() != date.getMonth())
                            fillMonth.call(this);
                        selectDate.call(this);
                    }
                    if (change_time) {
                        fillTime.call(this);
                    }

                    this.emitSignal("change", this.getDate());
                }
                return this;
            }
        },
        getDate: function() {
            return new Date(this.date.getTime());
        },
        toggleWeekNumber: function() {
            var cells = this.getElementsBySelector('.calendar_week_number_header').concat(
                this.getElementsBySelector('.calendar_week_number'));
            cells.invoke('toggle');
            return this;
        },
        toggleHeading: function() {
            var row = this.getElementsBySelector('.calendar_heading')[0];
            row.toggle();
            return this;
        },
        toggleTime: function() {
            var row = this.getElementsBySelector('.calendar_time')[0];
            row.toggle();
            return this;
        },
        getByDate: function(date) {
            var cell;
            this.dateCells.each(function(d) {
                if (!d.date) return;
                if (d.date.getFullYear() == date.getFullYear()
                    && d.date.getMonth() == date.getMonth()
                    && d.date.getDate() == date.getDate()) {
                    cell = d;
                    throw $break;
                }
            });
            return cell;
        },
        updateOnSignal: function(signal, element, format) {
            if (!(element = $(element)))
                return;
            var update_function = function() {
                updateElement.apply(this, [element, format].concat($A(arguments)));
            }.bind(this);
            this.signalConnect(signal, update_function);
            return this;
        },
        addSpecialDate: function(date) {
            if (typeof date != 'object')
                return;

            if (date instanceof Date) {
                var year = date.getFullYear();
                var month = date.getMonth();
                var date = date.getDate();
            } else {
                var year = date.year;
                var month = date.month;
                var date = date.date;
            }

            if (!date) return;

            this.options.specialDates.push({year: year, month: month, date: date});
            showSpecialDates.call(this);

            return this;
        },
        removeSpecialDate: function(date) {
            if (typeof date != 'object')
                return;

            if (date instanceof Date) {
                var year = date.getFullYear();
                var month = date.getMonth();
                var date = date.getDate();
            } else {
                var year = date.year;
                var month = date.month;
                var date = date.date;
            }

            if (!date) return;
            this.options.specialDates = this.options.specialDates.findAll(function(i) {
                if (i.year == year && i.month == month && i.date == date)
                    return false;
                return true;
            });
            showSpecialDates.call(this);

            return this;
        },

        _init: function() {
            this.options = Object.extend({
                fromYear: false,
                fromMonth: 0,
                toYear: false,
                toMonth: 0,
                startDate: new Date,
                showWeekNumber: true,
                showHeading: true,
                startOnMonday: true,
                showAdjacentMonths: true,
                markWeekends: true,
                showTime: true,
                astronomicalTime: true,
                specialDates: []
            }, arguments[1] || {});
            this.date = this.options.startDate;

            if (!("shortWeekDays" in Calendar)) {
                Calendar.shortWeekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                Calendar.weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                Calendar.shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                Calendar.months =
                    ['January', 'February', 'March', 'April',
                    'May', 'June', 'July', 'August',
                    'September', 'October', 'November', 'December'];
            }

            if (!this.options.showWeekNumber)
                this.toggleWeekNumber();
            if (!this.options.showHeading)
                this.toggleHeading();
            if (!this.options.showTime)
                this.toggleTime();

            this.dateCells = this.getElementsBySelector('.calendar_week_day');
            this.dateCells.each(function(d) { CalendarDate.create(d, this) }.bind(this));
            this._startDayChanged = true;
            fillTime.call(this);
            fillMonth.call(this);
            selectDate.call(this);
            this.setDate(this.date);

            connectHeadingSignals.call(this);
            connectTimeSignals.call(this);
            keyLogEvent(keyEventsCB.bindAsEventListener(this));
            registerFocus(this);

            this.emitSignal('load');
        }
    }
})());

var CalendarDate = {};
Object.extend(Object.extend(CalendarDate, Widget), (function() {
    function dateClickEvent(event) {
        var date = this.calendar.getDate();
        date.setDate(this.date.getDate());
        this.calendar.setDate(date);
    }

    return {
        /**
         * Sets whether the date is selected
         * @param {Boolean} selected True if the date should be selected
         * @returns The object
         * */
        setSelected: function(selected) {
            if (this.isSelected() == selected)
                return;

            if (!this.date || !this.calendar.options.showAdjacentMonths
                && this.date.getMonth() != this.calendar.date.getMonth())
                return;

            if (selected) {
                if (this.calendar.currentDate)
                    this.calendar.currentDate.setSelected(false);
                this.addClassName('calendar_week_day_selected');
                this.calendar.currentDate = this;

                this.calendar.emitSignal('select_date', this.getDate());
                this.emitSignal('select', this.getDate());
            } else {
                this.removeClassName('calendar_week_day_selected');
                if (this.calendar.currentDate == this)
                    this.calendar.currentDate = null;
                this.emitSignal('unselect', this.getDate());
            }

            return this;
        },
        /**
         * @returns True if the date is selected
         * @type Boolean
         * */
        isSelected: function() {
            return !!this.hasClassName('calendar_week_day_selected');
        },
        /**
         * Activates the calendar date 
         * @returns The object
         * */
        activate: function() {
            this.calendar.emitSignal('activate_date', this.getDate());
            this.emitSignal('activate', this.getDate());
            return this;
        },
        /**
         * @returns Date object of the current calendar date
         * @type Date
         * */
        getDate: function() {
            if (this.date)
                return new Date(this.date.getTime());
        },

        _init: function(id, calendar) {
            this.calendar = calendar;

            this.signalConnect('click', dateClickEvent.bindAsEventListener(this));
            this.signalConnect('dblclick', this.activate.bind(this));
        }
    }
})());
