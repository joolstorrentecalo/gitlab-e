<script>
/**
 * Renders SAST body text
 * [severity] ([confidence]): [name] in [link] : [line]
 */
import ReportLink from '~/reports/components/report_link.vue';
import ModalOpenName from '~/reports/components/modal_open_name.vue';
import { humanize } from '~/lib/utils/text_utility';

export default {
  name: 'SastIssueBody',

  components: {
    ReportLink,
    ModalOpenName,
  },

  props: {
    issue: {
      type: Object,
      required: true,
    },
    // failed || success
    status: {
      type: String,
      required: true,
    },
  },

  computed: {
    title() {
      const { severity, confidence, priority } = this.issue;

      if (severity) {
        if (confidence) {
          return `${humanize(severity)} (${humanize(confidence)})`;
        }
        return humanize(severity);
      } else if (confidence) {
        return `(${humanize(confidence)})`;
      }

      return priority;
    },
  },
};
</script>
<template>
  <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
    <div class="report-block-list-issue-description-text">
      {{ title }}:
      <modal-open-name :issue="issue" :status="status" />
    </div>

    <report-link v-if="issue.path" :issue="issue" />
  </div>
</template>
