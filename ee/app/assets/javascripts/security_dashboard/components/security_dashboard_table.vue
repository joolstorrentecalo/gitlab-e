<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlEmptyState } from '@gitlab/ui';
import Pagination from '~/vue_shared/components/pagination_links.vue';
import SecurityDashboardTableRow from './security_dashboard_table_row.vue';

export default {
  name: 'SecurityDashboardTable',
  components: {
    GlEmptyState,
    Pagination,
    SecurityDashboardTableRow,
  },
  computed: {
    ...mapState('vulnerabilities', [
      'errorLoadingVulnerabilities',
      'errorLoadingVulnerabilitiesCount',
      'isLoadingVulnerabilities',
      'pageInfo',
      'vulnerabilities',
    ]),
    ...mapGetters('filters', ['activeFilters']),
    ...mapGetters('vulnerabilities', ['dashboardListError']),
    showEmptyState() {
      return (
        this.vulnerabilities &&
        !this.vulnerabilities.length &&
        !this.errorLoadingVulnerabilities &&
        !this.errorLoadingVulnerabilitiesCount
      );
    },
    showPagination() {
      return this.pageInfo && this.pageInfo.total;
    },
  },
  methods: {
    ...mapActions('vulnerabilities', ['fetchVulnerabilities', 'openModal']),
    fetchPage(page) {
      this.fetchVulnerabilities({ ...this.activeFilters, page });
    },
  },
};
</script>

<template>
  <div class="ci-table js-security-dashboard-table" data-qa-selector="security_report_content">
    <div
      class="gl-responsive-table-row table-row-header vulnerabilities-row-header px-2"
      role="row"
    >
      <div class="table-section section-10" role="rowheader">{{ s__('Reports|Severity') }}</div>
      <div class="table-section section-10 ml-md-2" role="rowheader">
        {{ s__('Reports|Confidence') }}
      </div>
      <div class="table-section flex-grow-1" role="rowheader">
        {{ s__('Reports|Vulnerability') }}
      </div>
      <div class="table-section section-20" role="rowheader"></div>
    </div>

    <div class="flash-container">
      <div v-if="dashboardListError" class="flash-alert">
        <div class="flash-text container-fluid container-limited limit-container-width">
          {{
            s__(
              'Security Dashboard|Error fetching the vulnerability list. Please check your network connection and try again.',
            )
          }}
        </div>
      </div>
    </div>

    <template v-if="isLoadingVulnerabilities">
      <security-dashboard-table-row v-for="n in 10" :key="n" :is-loading="true" />
    </template>

    <template v-else>
      <security-dashboard-table-row
        v-for="vulnerability in vulnerabilities"
        :key="vulnerability.id"
        :vulnerability="vulnerability"
        @openModal="openModal({ vulnerability })"
      />

      <slot v-if="showEmptyState" name="emptyState">
        <gl-empty-state
          :title="s__(`We've found no vulnerabilities`)"
          :description="
            s__(
              `While it's rare to have no vulnerabilities, it can happen. In any event, we ask that you please double check your settings to make sure you've set up your dashboard correctly.`,
            )
          "
        />
      </slot>

      <pagination
        v-if="showPagination"
        :change="fetchPage"
        :page-info="pageInfo"
        class="justify-content-center prepend-top-default"
      />
    </template>
  </div>
</template>

<style>
.vulnerabilities-row-header {
  background-color: #fafafa;
  font-size: 14px;
}

.vulnerabilities-row .table-section,
.vulnerabilities-row-header .table-section {
  min-width: 120px;
}
</style>
