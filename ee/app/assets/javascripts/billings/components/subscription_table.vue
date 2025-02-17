<script>
import _ from 'underscore';
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import SubscriptionTableRow from './subscription_table_row.vue';
import { TABLE_TYPE_DEFAULT, TABLE_TYPE_FREE, TABLE_TYPE_TRIAL } from '../constants';

export default {
  name: 'SubscriptionTable',
  components: {
    SubscriptionTableRow,
    GlLoadingIcon,
  },
  props: {
    namespaceName: {
      type: String,
      required: true,
    },
    customerPortalUrl: {
      type: String,
      required: false,
      default: '',
    },
    planUpgradeHref: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState('subscription', ['isLoading', 'hasError', 'plan', 'tables', 'endpoint']),
    ...mapGetters('subscription', ['isFreePlan']),
    subscriptionHeader() {
      const planName = this.isFreePlan ? s__('SubscriptionTable|Free') : _.escape(this.plan.name);
      const suffix = !this.isFreePlan && this.plan.trial ? s__('SubscriptionTable|Trial') : '';

      return `${this.namespaceName}: ${planName} ${suffix}`;
    },
    upgradeButton() {
      if (!this.isFreePlan && !this.plan.upgradable) {
        return null;
      }

      return {
        text: s__('SubscriptionTable|Upgrade'),
        href:
          !this.isFreePlan && this.planUpgradeHref ? this.planUpgradeHref : this.customerPortalUrl,
      };
    },
    manageButton() {
      if (this.isFreePlan) {
        return null;
      }

      return {
        text: s__('SubscriptionTable|Manage'),
        href: this.customerPortalUrl,
      };
    },
    buttons() {
      return [this.upgradeButton, this.manageButton].filter(Boolean);
    },
    visibleRows() {
      let tableKey = TABLE_TYPE_DEFAULT;

      if (this.plan.code === null) {
        tableKey = TABLE_TYPE_FREE;
      } else if (this.plan.trial) {
        tableKey = TABLE_TYPE_TRIAL;
      }

      return this.tables[tableKey].rows;
    },
  },
  mounted() {
    this.fetchSubscription();
  },
  methods: {
    ...mapActions('subscription', ['fetchSubscription']),
  },
};
</script>

<template>
  <div>
    <div
      v-if="!isLoading && !hasError"
      class="card prepend-top-default subscription-table js-subscription-table"
    >
      <div class="js-subscription-header card-header">
        <strong>{{ subscriptionHeader }}</strong>
        <div class="controls">
          <a
            v-for="(button, index) in buttons"
            :key="button.text"
            :href="button.href"
            target="_blank"
            rel="noopener noreferrer"
            class="btn btn-inverted-secondary"
            :class="{ 'ml-2': index !== 0 }"
            >{{ button.text }}</a
          >
        </div>
      </div>
      <div class="card-body flex-grid d-flex flex-column flex-sm-row flex-md-row flex-lg-column">
        <subscription-table-row
          v-for="(row, i) in visibleRows"
          :key="`subscription-rows-${i}`"
          :header="row.header"
          :columns="row.columns"
          :is-free-plan="isFreePlan"
        />
      </div>
    </div>

    <gl-loading-icon
      v-else-if="isLoading && !hasError"
      :label="s__('SubscriptionTable|Loading subscriptions')"
      :size="3"
      class="prepend-top-10 append-bottom-10"
    />
  </div>
</template>
