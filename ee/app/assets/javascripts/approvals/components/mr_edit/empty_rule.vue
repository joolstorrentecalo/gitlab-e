<script>
import { mapActions } from 'vuex';
import { GlButton } from '@gitlab/ui';
import RuleInput from './rule_input.vue';
import EmptyRuleName from '../empty_rule_name.vue';

export default {
  components: {
    RuleInput,
    EmptyRuleName,
    GlButton,
  },
  props: {
    rule: {
      type: Object,
      required: true,
    },
    allowMultiRule: {
      type: Boolean,
      required: true,
    },
    eligibleApproversDocsPath: {
      type: String,
      required: false,
      default: '',
    },
    isMrEdit: {
      type: Boolean,
      default: true,
    },
    canEdit: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    ...mapActions({ openCreateModal: 'createModal/open' }),
  },
};
</script>

<template>
  <tr>
    <td colspan="2">
      <empty-rule-name :eligible-approvers-docs-path="eligibleApproversDocsPath" />
    </td>
    <td class="js-approvals-required">
      <rule-input :rule="rule" :is-mr-edit="isMrEdit" />
    </td>
    <td>
      <gl-button
        v-if="!allowMultiRule && canEdit"
        class="ml-auto btn-info btn-inverted"
        data-qa-selector="add_approvers_button"
        @click="openCreateModal(null)"
      >
        {{ __('Add approval rule') }}
      </gl-button>
    </td>
  </tr>
</template>
