import { newDate } from '~/lib/utils/datetime_utility';

export default {
  methods: {
    /**
     * Check if current epic starts within current week (timeline cell)
     */
    hasStartDateForWeek() {
      const firstDayOfWeek = this.timeframeItem;
      const lastDayOfWeek = newDate(this.timeframeItem);
      lastDayOfWeek.setDate(lastDayOfWeek.getDate() + 6);

      return (
        this.epicStartDateValues.time >= firstDayOfWeek.getTime() &&
        this.epicStartDateValues.time <= lastDayOfWeek.getTime()
      );
    },
    /**
     * Return last date of the week from provided timeframeItem
     */
    getLastDayOfWeek(timeframeItem) {
      const lastDayOfWeek = newDate(timeframeItem);
      lastDayOfWeek.setDate(lastDayOfWeek.getDate() + 6);
      return lastDayOfWeek;
    },
    /**
     * Check if current epic ends within current week (timeline cell)
     */
    isTimeframeUnderEndDateForWeek(timeframeItem) {
      const lastDayOfWeek = this.getLastDayOfWeek(timeframeItem);
      return this.epicEndDateValues.time <= lastDayOfWeek.getTime();
    },
    /**
     * Return timeline bar width for current week (timeline cell) based on
     * cellWidth, days in week (7) and day of the week (non-zero based index)
     */
    getBarWidthForSingleWeek(cellWidth, day) {
      const dayWidth = cellWidth / 7;
      const barWidth = day === 7 ? cellWidth : dayWidth * day;

      return Math.min(cellWidth, barWidth);
    },
    /**
     * In case startDate for any epic is undefined or is out of range
     * for current timeframe, we have to provide specific offset while
     * positioning it to ensure that;
     *
     * 1. Timeline bar starts at correct position based on start date.
     * 2. Bar starts exactly at the start of cell in case start date is `1`.
     * 3. A "triangle" shape is shown at the beginning of timeline bar
     *    when startDate is out of range.
     *
     * Implementation of this method is identical to
     * MonthsPresetMixin#getTimelineBarStartOffsetForMonths
     */
    getTimelineBarStartOffsetForWeeks() {
      const daysInWeek = 7;
      const dayWidth = this.$options.cellWidth / daysInWeek;
      const startDate = this.epicStartDateValues.day + 1;
      const firstDayOfWeek = this.timeframeItem.getDay() + 1;

      if (
        this.epic.startDateOutOfRange ||
        (this.epic.startDateUndefined && this.epic.endDateOutOfRange)
      ) {
        return '';
      } else if (startDate === firstDayOfWeek) {
        /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
        return 'left: 0;';
      }

      /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
      return `left: ${startDate * dayWidth - dayWidth / 2}px;`;
    },
    /**
     * This method is externally only called when current timeframe cell has timeline
     * bar to show. So when this method is called, we iterate over entire timeframe
     * array starting from current timeframeItem.
     *
     * For eg;
     *  If timeframe range for 6 weeks is;
     *    May 27, Jun 3, Jun 10, Jun 17, Jun 24, Jul 1
     *
     *  And if Epic starts in May 30 and ends on June 20.
     *
     *  Then this method will iterate over timeframe as;
     *    May 27 => Jun 17
     *  And will add up width(see 1.) for timeline bar for each week in iteration
     *  based on provided start and end dates.
     *
     *  1. Width from date is calculated by totalWidthCell / totalDaysInWeek = widthOfSingleDay
     *     and then dayOfWeek x widthOfSingleDay = totalBarWidth
     *
     * Implementation of this method is identical to
     * MonthsPresetMixin#getTimelineBarWidthForMonths
     */
    getTimelineBarWidthForWeeks() {
      let timelineBarWidth = 0;

      const indexOfCurrentWeek = this.timeframe.indexOf(this.timeframeItem);
      const { cellWidth } = this.$options;
      const epicStartDate = this.epicStartDateValues;
      const epicEndDate = this.epicEndDateValues;

      for (let i = indexOfCurrentWeek; i < this.timeframe.length; i += 1) {
        if (i === indexOfCurrentWeek) {
          if (this.isTimeframeUnderEndDateForWeek(this.timeframe[i])) {
            timelineBarWidth += this.getBarWidthForSingleWeek(
              cellWidth,
              epicEndDate.day - epicStartDate.day + 1,
            );
            break;
          } else {
            const date = epicStartDate.day === 0 ? 7 : 7 - epicStartDate.day;
            timelineBarWidth += this.getBarWidthForSingleWeek(cellWidth, date);
          }
        } else if (this.isTimeframeUnderEndDateForWeek(this.timeframe[i])) {
          timelineBarWidth += this.getBarWidthForSingleWeek(cellWidth, epicEndDate.day + 1);
          break;
        } else {
          timelineBarWidth += this.getBarWidthForSingleWeek(cellWidth, 7);
        }
      }

      return timelineBarWidth;
    },
  },
};
