var Calendar = {};
Object.extend(Object.extend(Calendar, Widget), (function() {
    const weeks_in_month = 6;

    function fillMonth() {
        var start_day = this.options.startOnMonday ? 1 : 0;
        var year = this.date.getFullYear();
        var month = this.date.getMonth();
        var heading_cells = this.getElementsBySelector('.calendar_heading')[0].cells;
        var week_days = this.getElementsBySelector('.calendar_week_days')[0];
        var date = new Date(year, month, 1);

        $(heading_cells[1]).down().value = this.months[month];
        $(heading_cells[4]).down().value = year;

        while (date.getDay() != start_day)
            date.decrementDate();

        if (start_day == 0) {
            Element.extend(week_days.cells[1]).update(this.weekDays[6]).addClassName('calendar_weekend_header');
            for (day = 0; day < 6; day++) {
                var cell = Element.extend(week_days.cells[day + 2]);
                cell.update(this.weekDays[day]);
                if (day == 5)
                    cell.addClassName('calendar_weekend_header');
                else
                    cell.removeClassName('calendar_weekend_header');
            }
        } else {
            for (day = 0; day < 7; day++) {
                var cell = Element.extend(week_days.cells[day + 1]);
                cell.update(this.weekDays[day]);
                if (day == 5 || day == 6)
                    cell.addClassName('calendar_weekend_header');
                else
                    cell.removeClassName('calendar_weekend_header');
            }
        }

        var week_rows = this.getElementsBySelector('.calendar_week');
        for (week = 0; week < weeks_in_month; week++) {
            var row = week_rows[week];
            Element.extend(row.cells[0]).update(date.getWeek());

            for (day = 0; day < 7; day++) {
                var cell = Element.extend(row.cells[day + 1]);
                var this_month = date.getMonth();
                if (this.options.showAdjacentDays) {
                    if (this_month != month)
                        cell.addClassName('calendar_week_day_disabled');
                    else
                        cell.removeClassName('calendar_week_day_disabled');
                    cell.update(date.getDate());
                } else {
                    if (this_month == month)
                        cell.update(date.getDate());
                    else cell.update();
                }
                if ([0,6].include(date.getDay()))
                    cell.addClassName('calendar_weekend');
                else
                    cell.removeClassName('calendar_weekend');
                date.incrementDate();
            }
        }
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
            this.setDate(date);
        }
    }
    function monthBlurEvent(event) {
        var element = event.element();
        element.value = this.months[this.date.getMonth()];
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
            this.setDate(date);
        }
    }
    function yearBlurEvent(event) {
        var element = event.element();
        element.value = this.date.getFullYear();
        element.removeClassName('calendar_year_selected');
    }

    return {
        setDate: function(date) {
            if (date instanceof Date) {
                var old_date = this.date;
                this.date = date;
                if (old_date.getFullYear() != date.getFullYear()
                        || old_date.getMonth() != date.getMonth())
                    fillMonth.call(this);

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
        },
        toggleHeading: function() {
            var row = this.getElementsBySelector('.calendar_heading')[0];
            row.toggle();
        },


        _init: function(id) {
            this.options = Object.extend({
                startDate: new Date,
                showWeekNumber: true,
                showHeading: true,
                startOnMonday: true,
                showAdjacentDays: true,
                markWeekends: true
            }, arguments[1] || {});
            this.date = this.options.startDate;
            this.weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            this.months =
                ['January', 'February', 'March', 'April',
                'May', 'June', 'July', 'August',
                'September', 'October', 'November', 'December'];

            if (!this.options.showWeekNumber)
                this.toggleWeekNumber();
            if (!this.options.showHeading)
                this.toggleHeading();

            fillMonth.call(this);
            connectHeadingSignals.call(this)
            this.emitSignal('load');
        }
    }
})());
