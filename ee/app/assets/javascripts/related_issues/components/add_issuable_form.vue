<script>
import { GlFormGroup, GlFormRadioGroup, GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import RelatedIssuableInput from './related_issuable_input.vue';
import {
  issuableTypesMap,
  itemAddFailureTypesMap,
  linkedIssueTypesMap,
  addRelatedIssueErrorMap,
  addRelatedItemErrorMap,
} from '../constants';

export default {
  name: 'AddIssuableForm',
  components: {
    GlFormGroup,
    GlFormRadioGroup,
    GlLoadingIcon,
    RelatedIssuableInput,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    inputValue: {
      type: String,
      required: true,
    },
    pendingReferences: {
      type: Array,
      required: false,
      default: () => [],
    },
    autoCompleteSources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
    pathIdSeparator: {
      type: String,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: issuableTypesMap.ISSUE,
    },
    hasError: {
      type: Boolean,
      required: false,
      default: false,
    },
    itemAddFailureType: {
      type: String,
      required: false,
      default: itemAddFailureTypesMap.NOT_FOUND,
    },
  },
  data() {
    return {
      linkedIssueType: linkedIssueTypesMap.RELATES_TO,
      linkedIssueTypes: [
        {
          text: __('relates to'),
          value: linkedIssueTypesMap.RELATES_TO,
        },
        {
          text: __('blocks'),
          value: linkedIssueTypesMap.BLOCKS,
        },
        {
          text: __('is blocked by'),
          value: linkedIssueTypesMap.IS_BLOCKED_BY,
        },
      ],
    };
  },
  computed: {
    isSubmitButtonDisabled() {
      return (
        (this.inputValue.length === 0 && this.pendingReferences.length === 0) || this.isSubmitting
      );
    },
    addRelatedErrorMessage() {
      if (this.itemAddFailureType === itemAddFailureTypesMap.NOT_FOUND) {
        return addRelatedIssueErrorMap[this.issuableType];
      }
      // Only other failure is MAX_NUMBER_OF_CHILD_EPICS at the moment
      return addRelatedItemErrorMap[this.itemAddFailureType];
    },
  },
  methods: {
    onPendingIssuableRemoveRequest(params) {
      this.$emit('pendingIssuableRemoveRequest', params);
    },
    onFormSubmit() {
      this.$emit('addIssuableFormSubmit', {
        pendingReferences: this.$refs.relatedIssuableInput.$refs.input.value,
        linkedIssueType: this.linkedIssueType,
      });
    },
    onFormCancel() {
      this.$emit('addIssuableFormCancel');
    },
    onAddIssuableFormInput(params) {
      this.$emit('addIssuableFormInput', params);
    },
    onAddIssuableFormBlur(params) {
      this.$emit('addIssuableFormBlur', params);
    },
  },
};
</script>

<template>
  <form @submit.prevent="onFormSubmit">
    <template v-if="glFeatures.issueLinkTypes">
      <gl-form-group
        :label="__('The current issue')"
        label-for="linked-issue-type-radio"
        label-class="label-bold"
        class="mb-2"
      >
        <gl-form-radio-group
          id="linked-issue-type-radio"
          v-model="linkedIssueType"
          :options="linkedIssueTypes"
          :checked="linkedIssueType"
        />
      </gl-form-group>
      <p class="bold">
        {{ __('the following issue(s)') }}
      </p>
    </template>
    <related-issuable-input
      ref="relatedIssuableInput"
      :focus-on-mount="true"
      :references="pendingReferences"
      :path-id-separator="pathIdSeparator"
      :input-value="inputValue"
      :auto-complete-sources="autoCompleteSources"
      :auto-complete-options="{ issues: true, epics: true }"
      :issuable-type="issuableType"
      @pendingIssuableRemoveRequest="onPendingIssuableRemoveRequest"
      @formCancel="onFormCancel"
      @addIssuableFormBlur="onAddIssuableFormBlur"
      @addIssuableFormInput="onAddIssuableFormInput"
    />
    <p v-if="hasError" class="gl-field-error">
      {{ addRelatedErrorMessage }}
    </p>
    <div class="add-issuable-form-actions clearfix">
      <button
        ref="addButton"
        :disabled="isSubmitButtonDisabled"
        type="submit"
        class="js-add-issuable-form-add-button btn btn-success float-left qa-add-issue-button"
        :class="{ disabled: isSubmitButtonDisabled }"
      >
        {{ __('Add') }}
        <gl-loading-icon v-if="isSubmitting" ref="loadingIcon" :inline="true" />
      </button>
      <button type="button" class="btn btn-default float-right" @click="onFormCancel">
        {{ __('Cancel') }}
      </button>
    </div>
  </form>
</template>
