<script>
import { escape } from 'underscore';
import { mapState } from 'vuex';
import { __, sprintf, n__ } from '~/locale';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { GlTable, GlLink, GlIcon, GlAvatarLink, GlAvatar } from '@gitlab/ui';

export default {
  name: 'MergeRequestTable',
  components: {
    GlTable,
    GlLink,
    GlIcon,
    GlAvatarLink,
    GlAvatar,
  },
  computed: {
    ...mapState(['mergeRequests']),
  },
  methods: {
    getTimeAgoString(createdAt) {
      return sprintf(__('opened %{timeAgo}'), {
        timeAgo: escape(getTimeago().format(createdAt)),
      });
    },
    formatReviewTime(hours) {
      if (hours >= 24) {
        const days = Math.floor(hours / 24);
        return n__('1 day', '%d days', days);
      } else if (hours >= 1 && hours < 24) {
        return n__('1 hour', '%d hours', hours);
      }

      return __('< 1 hour');
    },
  },
  tableHeaderFields: [
    {
      key: 'mr_details',
      label: __('Merge Request'),
      thClass: 'w-30p',
      tdClass: 'table-col d-flex align-items-center',
    },
    {
      key: 'review_time',
      label: __('Review time'),
      class: 'text-right',
      tdClass: 'table-col d-flex align-items-center d-sm-table-cell',
    },
    {
      key: 'author',
      label: __('Author'),
      tdClass: 'table-col d-flex align-items-center d-sm-table-cell',
    },
    {
      key: 'notes_count',
      label: __('Comments'),
      class: 'text-right',
      tdClass: 'table-col d-flex align-items-center d-sm-table-cell',
    },
    {
      key: 'diff_stats',
      label: __('Commits'),
      class: 'text-right',
      tdClass: 'table-col d-flex align-items-center d-sm-table-cell',
    },
    {
      key: 'line_changes',
      label: __('Line changes'),
      class: 'text-right',
      tdClass: 'table-col d-flex align-items-center d-sm-table-cell',
    },
  ],
};
</script>

<template>
  <gl-table
    class="my-3"
    :fields="$options.tableHeaderFields"
    :items="mergeRequests"
    stacked="sm"
    thead-class="thead-white border-bottom"
  >
    <template #mr_details="items">
      <div class="d-flex flex-column flex-grow align-items-end align-items-sm-start">
        <div class="mr-title str-truncated my-2">
          <gl-link :href="items.item.web_url" target="_blank" class="font-weight-bold text-plain">{{
            items.item.title
          }}</gl-link>
        </div>
        <ul class="horizontal-list list-items-separated text-secondary mb-0">
          <li>!{{ items.item.iid }}</li>
          <li>{{ getTimeAgoString(items.item.created_at) }}</li>
          <li v-if="items.item.milestone">
            <span class="d-flex align-items-center">
              <gl-icon name="clock" class="mr-2" />
              {{ items.item.milestone.title }}
            </span>
          </li>
        </ul>
      </div>
    </template>

    <template #review_time="{ value }">
      <template v-if="value">
        {{ formatReviewTime(value) }}
      </template>
      <template v-else>
        &ndash;
      </template>
    </template>

    <template #author="{ value }">
      <gl-avatar-link target="blank" :href="value.web_url">
        <gl-avatar :size="24" :src="value.avatar_url" :entity-name="value.name" />
      </gl-avatar-link>
    </template>

    <template #diff_stats="{ value }">
      <span>{{ value.commits_count }}</span>
    </template>

    <template #line_changes="items">
      <span class="font-weight-bold cgreen"> +{{ items.item.diff_stats.additions }} </span>
      <span class="font-weight-bold cred"> -{{ items.item.diff_stats.deletions }} </span>
    </template>
  </gl-table>
</template>
