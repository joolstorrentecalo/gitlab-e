<script>
import { GlSkeletonLoading, GlTable, GlAvatar } from '@gitlab/ui';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import { mapState, mapActions } from 'vuex';
import { __, s__ } from '~/locale';

export default {
  components: {
    GlSkeletonLoading,
    GlTable,
    GlAvatar,
    TablePagination,
  },
  computed: {
    ...mapState(['isInitialLoadInProgress', 'members', 'pageInfo']),
  },
  fields: [
    {
      key: 'name',
      label: __('User'),
    },
    {
      key: 'identity',
      label: s__('GroupSAML|Identity'),
    },
  ],
  mounted() {
    this.fetchPage();
  },
  methods: {
    ...mapActions(['fetchPage']),
    change(nextPage) {
      this.fetchPage(nextPage);
    },
  },
};
</script>
<template>
  <div class="prepend-top-default">
    <gl-skeleton-loading v-if="isInitialLoadInProgress" />
    <gl-table v-else :items="members" :fields="$options.fields">
      <template #name="{ item }">
        <span class="d-flex">
          <gl-avatar v-gl-tooltip :src="item.avatar_url" :size="48" />
          <div class="ml-2">
            <div class="font-weight-bold">
              <a
                class="js-user-link"
                :href="item.web_url"
                :data-user-id="item.id"
                :data-username="item.username"
              >
                {{ item.name }}
              </a>
            </div>
            <div class="cgray">@{{ item.username }}</div>
          </div>
        </span>
      </template>
      <template #identity="{ value }">
        <span class="font-weight-bold">{{ value }}</span>
      </template>
    </gl-table>
    <table-pagination :page-info="pageInfo" :change="change" />
  </div>
</template>
