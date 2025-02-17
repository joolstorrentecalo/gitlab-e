<script>
/* eslint-disable @gitlab/vue-i18n/no-bare-strings */
/**
 * Renders a deploy board.
 *
 * A deploy board is composed by:
 * - Information area with percentage of completion.
 * - Instances with status.
 * - Button Actions.
 * [Mockup](https://gitlab.com/gitlab-org/gitlab-foss/uploads/2f655655c0eadf655d0ae7467b53002a/environments__deploy-graphic.png)
 */
import _ from 'underscore';
import { GlLoadingIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import deployBoardSvg from 'ee_empty_states/icons/_deploy_board.svg';
import { n__, s__, sprintf } from '~/locale';
import { STATUS_MAP, CANARY_STATUS } from '../constants';

export default {
  components: {
    instanceComponent: () => import('ee_component/vue_shared/components/deployment_instance.vue'),
    GlLoadingIcon,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    deployBoardData: {
      type: Object,
      required: true,
    },
    deployBoardsHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    isEmpty: {
      type: Boolean,
      required: true,
    },
    environmentName: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    hasLegacyAppLabel: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    canRenderDeployBoard() {
      return !this.isEmpty && !_.isEmpty(this.deployBoardData);
    },
    legacyLabelWarningMessage() {
      return sprintf(
        s__(
          'DeployBoard|Matching on the %{appLabel} label has been removed for deploy boards. To see all instances on your board, you must update your chart and redeploy.',
        ),
        {
          appLabel: '<code>app</code>',
        },
        false,
      );
    },
    canRenderEmptyState() {
      return this.isEmpty;
    },
    instanceCount() {
      const { instances } = this.deployBoardData;

      return Array.isArray(instances) ? instances.length : 0;
    },
    instanceIsCompletedCount() {
      const completionPercentage = this.deployBoardData.completion / 100;
      const completionCount = Math.floor(completionPercentage * this.instanceCount);

      return Number.isNaN(completionCount) ? 0 : completionCount;
    },
    instanceIsCompletedText() {
      const title = n__('instance completed', 'instances completed', this.instanceIsCompletedCount);

      return `${this.instanceIsCompletedCount} ${title}`;
    },
    instanceTitle() {
      return n__('Instance', 'Instances', this.instanceCount);
    },
    deployBoardSvg() {
      return deployBoardSvg;
    },
    deployBoardActions() {
      return this.deployBoardData.rollback_url || this.deployBoardData.abort_url;
    },
    statuses() {
      // Canary is not a pod status but it needs to be in the legend.
      // Hence adding it here.
      return {
        ...STATUS_MAP,
        CANARY_STATUS,
      };
    },
  },
};
</script>
<template>
  <div class="js-deploy-board deploy-board">
    <gl-loading-icon v-if="isLoading" class="loading-icon" />
    <template v-else>
      <div v-if="hasLegacyAppLabel" class="bs-callout bs-callout-warning mb-0 mt-0">
        <span v-html="legacyLabelWarningMessage"></span>
        <gl-link target="blank" :href="deployBoardsHelpPath">
          <strong>{{ __('More Information') }}</strong>
        </gl-link>
      </div>

      <div v-if="canRenderDeployBoard" class="deploy-board-information p-3">
        <div class="deploy-board-information">
          <section class="deploy-board-status">
            <span v-gl-tooltip :title="instanceIsCompletedText">
              <span ref="percentage" class="text-center text-plain gl-font-size-large"
                >{{ deployBoardData.completion }}%</span
              >
              <span class="text text-center text-secondary">{{ __('Complete') }}</span>
            </span>
          </section>

          <section class="deploy-board-instances">
            <span class="deploy-board-instances-text gl-font-size-14 text-secondary">
              {{ instanceTitle }} ({{ instanceCount }})
            </span>

            <div class="deploy-board-instances-container d-flex flex-wrap flex-row">
              <template v-for="(instance, i) in deployBoardData.instances">
                <instance-component
                  :key="i"
                  :status="instance.status"
                  :tooltip-text="instance.tooltip"
                  :environment-name="environmentName"
                  :pod-name="instance.pod_name"
                  :project-path="projectPath"
                  :stable="instance.stable"
                />
              </template>
            </div>
            <div class="deploy-board-legend d-flex mt-3">
              <div
                v-for="status in statuses"
                :key="status.text"
                class="d-flex justify-content-center align-items-center mr-3"
              >
                <instance-component :status="status.class" :stable="status.stable" />
                <span class="legend-text ml-2">{{ status.text }}</span>
              </div>
            </div>
          </section>

          <section v-if="deployBoardActions" class="deploy-board-actions">
            <gl-link
              v-if="deployBoardData.rollback_url"
              :href="deployBoardData.rollback_url"
              class="btn"
              data-method="post"
              rel="nofollow"
              >{{ __('Rollback') }}</gl-link
            >
            <gl-link
              v-if="deployBoardData.abort_url"
              :href="deployBoardData.abort_url"
              class="btn btn-red btn-inverted"
              data-method="post"
              rel="nofollow"
              >{{ __('Abort') }}</gl-link
            >
          </section>
        </div>
      </div>

      <div v-if="canRenderEmptyState" class="deploy-board-empty">
        <section class="deploy-board-empty-state-svg" v-html="deployBoardSvg"></section>

        <section class="deploy-board-empty-state-text">
          <span class="deploy-board-empty-state-title d-flex">{{
            __('Kubernetes deployment not found')
          }}</span>
          <span>
            To see deployment progress for your environments, make sure you are deploying to
            <code>$KUBE_NAMESPACE</code> and annotating with
            <code>app.gitlab.com/app=$CI_PROJECT_PATH_SLUG</code>
            and <code>app.gitlab.com/env=$CI_ENVIRONMENT_SLUG</code>.
          </span>
        </section>
      </div>
    </template>
  </div>
</template>
