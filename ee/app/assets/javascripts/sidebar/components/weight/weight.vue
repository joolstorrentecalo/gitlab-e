<script>
import $ from 'jquery';
import { GlLoadingIcon } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import Tracking from '~/tracking';
import eventHub from '~/sidebar/event_hub';
import tooltip from '~/vue_shared/directives/tooltip';
import icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    icon,
    GlLoadingIcon,
  },
  directives: {
    tooltip,
  },
  mixins: [Tracking.mixin({ label: 'right_sidebar' })],
  props: {
    fetching: {
      type: Boolean,
      required: false,
      default: false,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    weight: {
      type: [String, Number],
      required: false,
      default: '',
    },
    weightNoneValue: {
      type: String,
      required: true,
      default: __('None'),
    },
    editable: {
      type: Boolean,
      required: false,
      default: false,
    },
    id: {
      type: [String, Number],
      required: false,
      default: '',
    },
  },
  data() {
    return {
      hasValidInput: true,
      shouldShowEditField: false,
      collapsedAfterUpdate: false,
    };
  },
  computed: {
    tracking() {
      return {
        // eslint-disable-next-line no-underscore-dangle
        category: this.$options._componentTag,
      };
    },
    isNoValue() {
      return this.checkIfNoValue(this.weight);
    },
    collapsedWeightLabel() {
      let label = this.weight;
      if (this.checkIfNoValue(this.weight)) {
        label = this.noValueLabel;
      }

      // Truncate with ellipsis after five digits
      if (this.weight > 99999) {
        label = `${this.weight.toString().substr(0, 5)}&hellip;`;
      }

      return label;
    },
    noValueLabel() {
      return s__('Sidebar|None');
    },
    changeWeightLabel() {
      return s__('Sidebar|Change weight');
    },
    dropdownToggleLabel() {
      let label = this.weight;
      if (this.checkIfNoValue(this.weight)) {
        label = s__('Sidebar|Weight');
      }

      return label;
    },
    shouldShowWeight() {
      return !this.fetching && !this.shouldShowEditField;
    },
    tooltipTitle() {
      let tooltipTitle = s__('Sidebar|Weight');

      if (!this.checkIfNoValue(this.weight)) {
        tooltipTitle += ` ${this.weight}`;
      }

      return tooltipTitle;
    },
  },
  methods: {
    checkIfNoValue(weight) {
      return weight === undefined || weight === null || weight === this.weightNoneValue;
    },
    onEditClick(shouldShowEditField = true) {
      this.showEditField(shouldShowEditField);

      this.track('click_edit_button', { property: 'weight' });
    },
    showEditField(bool = true) {
      this.shouldShowEditField = bool;

      if (this.shouldShowEditField) {
        this.$nextTick(() => {
          this.$refs.editableField.focus();
        });
      }
    },
    onCollapsedClick() {
      if (this.editable) {
        this.showEditField(true);
      }
      this.collapsedAfterUpdate = true;
    },
    onSubmit(e) {
      const { value } = e.target;
      const validatedValue = parseInt(value, 10);
      const isNewValue = validatedValue !== this.weight;

      this.hasValidInput = validatedValue >= 0 || value === '';

      if (!this.loading && this.hasValidInput) {
        $(this.$el).trigger('hidden.gl.dropdown');

        if (isNewValue) {
          eventHub.$emit('updateWeight', value, this.id);
        }

        this.showEditField(false);
      }
    },
    removeWeight() {
      eventHub.$emit('updateWeight', '', this.id);
    },
  },
};
</script>

<template>
  <div :class="{ 'collapse-after-update': collapsedAfterUpdate }" class="block weight">
    <div
      v-tooltip
      :title="tooltipTitle"
      class="sidebar-collapsed-icon js-weight-collapsed-block"
      data-container="body"
      data-placement="left"
      data-boundary="viewport"
      @click="onCollapsedClick"
    >
      <icon :size="16" name="weight" />
      <gl-loading-icon v-if="fetching" class="js-weight-collapsed-loading-icon" />
      <span v-else class="js-weight-collapsed-weight-label" v-html="collapsedWeightLabel"></span>
    </div>
    <div class="title hide-collapsed">
      {{ s__('Sidebar|Weight') }}
      <gl-loading-icon v-if="fetching || loading" :inline="true" class="js-weight-loading-icon" />
      <a
        v-if="editable"
        class="float-right js-weight-edit-link"
        data-qa-selector="edit_weight_link"
        href="#"
        @click="onEditClick(!shouldShowEditField)"
        >{{ __('Edit') }}</a
      >
    </div>
    <div v-if="shouldShowEditField" class="hide-collapsed">
      <input
        ref="editableField"
        :value="weight"
        class="form-control"
        data-qa-selector="weight_input_field"
        type="text"
        :placeholder="__('Enter a number')"
        @blur="onSubmit"
        @keydown.enter="onSubmit"
      />
      <span v-if="!hasValidInput" class="gl-field-error">
        <icon :size="24" name="merge-request-close-m" />
        {{ s__('Sidebar|Only numeral characters allowed') }}
      </span>
    </div>
    <div v-if="shouldShowWeight" class="value hide-collapsed js-weight-weight-label">
      <span v-if="!isNoValue">
        <strong class="js-weight-weight-label-value" data-qa-selector="weight_label_value">{{
          weight
        }}</strong>
        <span v-if="editable">
          -
          <a
            class="btn-default-hover-link js-weight-remove-link"
            data-qa-selector="remove_weight_link"
            href="#"
            @click="removeWeight"
            >{{ __('remove weight') }}</a
          >
        </span>
      </span>
      <span v-else class="no-value" data-qa-selector="weight_no_value_content">{{
        noValueLabel
      }}</span>
    </div>
  </div>
</template>
