<script>
import _ from 'underscore';
import { GlTooltipDirective, GlLink, GlBadge } from '@gitlab/ui';
import Alerts from 'ee/vue_shared/dashboards/components/alerts.vue';
import TimeAgo from 'ee/vue_shared/dashboards/components/time_ago.vue';
import { STATUS_FAILED } from 'ee/vue_shared/dashboards/constants';
import ProjectPipeline from 'ee/vue_shared/dashboards/components/project_pipeline.vue';
import { s__, __, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import Commit from '~/vue_shared/components/commit.vue';
import EnvironmentHeader from './environment_header.vue';

export default {
  components: {
    EnvironmentHeader,
    UserAvatarLink,
    GlLink,
    GlBadge,
    Commit,
    Alerts,
    ProjectPipeline,
    TimeAgo,
    Icon,
  },
  directives: {
    'gl-tooltip': GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    environment: {
      type: Object,
      required: true,
    },
  },
  tooltips: {
    timeAgo: __('Finished'),
    triggerer: __('Triggerer'),
    job: s__('EnvironmentsDashboard|Job: %{job}'),
  },
  noDeploymentMessage: __('This environment has no deployments yet.'),
  computed: {
    hasPipelineFailed() {
      return (
        this.lastPipeline &&
        this.lastPipeline.details &&
        this.lastPipeline.details.status &&
        this.lastPipeline.details.status.group === STATUS_FAILED
      );
    },
    hasPipelineErrors() {
      return this.environment.alert_count > 0;
    },
    cardClasses() {
      return {
        'dashboard-card-body-warning': !this.hasPipelineFailed && this.hasPipelineErrors,
        'dashboard-card-body-failed': this.hasPipelineFailed,
        'bg-secondary': !this.hasPipelineFailed && !this.hasPipelineErrors,
        'd-flex flex-column justify-content-center align-items-center': !this.lastDeployment,
      };
    },
    user() {
      return this.lastDeployment && !_.isEmpty(this.lastDeployment.user)
        ? this.lastDeployment.user
        : null;
    },
    lastPipeline() {
      return !_.isEmpty(this.environment.last_pipeline) ? this.environment.last_pipeline : null;
    },
    lastDeployment() {
      return !_.isEmpty(this.environment.last_deployment) ? this.environment.last_deployment : null;
    },
    deployable() {
      return this.lastDeployment ? this.lastDeployment.deployable : null;
    },
    commit() {
      return !_.isEmpty(this.lastDeployment.commit) ? this.lastDeployment.commit : {};
    },
    jobTooltip() {
      return this.deployable
        ? sprintf(this.$options.tooltips.job, { job: this.buildName })
        : s__('EnvironmentDashboard|Created through the Deployment API');
    },
    commitRef() {
      return this.lastDeployment && !_.isEmpty(this.lastDeployment.commit)
        ? {
            ...this.lastDeployment.commit,
            ...this.lastDeployment.ref,
            ref_url: this.lastDeployment.ref.ref_path,
          }
        : {};
    },
    commitAuthor() {
      return (
        this.commit.author || {
          avatar_url: this.commit.author_gravatar_url,
          path: `mailto:${_.escape(this.commit.author_email)}`,
          username: this.commit.author_name,
        }
      );
    },
    finishedTime() {
      return this.lastDeployment.deployed_at;
    },
    finishedTimeTitle() {
      return this.tooltipTitle(this.finishedTime);
    },
    shouldShowTimeAgo() {
      return Boolean(this.finishedTime);
    },
    buildName() {
      return this.deployable
        ? `${this.deployable.name} #${this.deployable.id}`
        : s__('EnvironmentDashboard|API');
    },
  },
};
</script>
<template>
  <div class="dashboard-card card border-0">
    <environment-header
      :environment="environment"
      :has-pipeline-failed="hasPipelineFailed"
      :has-errors="hasPipelineErrors"
    />

    <div :class="cardClasses" class="dashboard-card-body card-body">
      <div v-if="lastDeployment" class="row">
        <div class="col-1 align-self-center">
          <user-avatar-link
            v-if="user"
            :link-href="user.path"
            :img-src="user.avatar_url"
            :tooltip-text="user.name"
            :img-size="32"
          />
        </div>

        <div class="col-10 col-sm-7 pr-0 pl-5 align-self-center align-middle ci-table">
          <div class="branch-commit">
            <icon name="work" />
            <gl-link
              v-if="deployable"
              v-gl-tooltip="jobTooltip"
              :href="deployable.build_path"
              class="str-truncated"
            >
              {{ buildName }}
            </gl-link>
            <gl-badge v-else v-gl-tooltip="jobTooltip" variant="primary">{{ buildName }}</gl-badge>
          </div>
          <commit
            :tag="lastDeployment.tag"
            :commit-ref="commitRef"
            :short-sha="commit.short_id"
            :commit-url="commit.commit_url"
            :title="commit.title"
            :author="commitAuthor"
            :show-branch="true"
          />
        </div>

        <div
          class="col-sm-4 mt-0 pl-5 pl-sm-0 offset-1 offset-sm-0 text-sm-right align-self-center col-12 d-sm-block"
        >
          <time-ago
            v-if="shouldShowTimeAgo"
            :time="finishedTime"
            :tooltip-text="$options.tooltips.timeAgo"
          />
          <alerts
            v-if="environment.alert_count > 0"
            :count="environment.alert_count"
            :last-alert="environment.last_alert"
          />
        </div>

        <div v-if="lastPipeline" class="col-12">
          <project-pipeline
            :project-name="environment.name_with_namespace"
            :last-pipeline="lastPipeline"
            :has-pipeline-failed="hasPipelineFailed"
          />
        </div>
      </div>

      <div v-else class="h-100 d-flex justify-content-center align-items-center">
        <div class="text-plain text-metric text-center bold">
          {{ $options.noDeploymentMessage }}
        </div>
      </div>
    </div>
  </div>
</template>
