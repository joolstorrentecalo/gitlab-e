<script>
import {
  GlButton,
  GlIcon,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
  GlLink,
  GlEmptyState,
  GlTable,
} from '@gitlab/ui';
import _ from 'underscore';
import Tracking from '~/tracking';
import PackageInformation from './information.vue';
import NpmInstallation from './npm_installation.vue';
import MavenInstallation from './maven_installation.vue';
import ConanInstallation from './conan_installation.vue';
import PackageTags from './package_tags.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { generatePackageInfo } from '../utils';
import { __, s__, sprintf } from '~/locale';
import { PackageType, TrackingActions } from '../../shared/constants';
import { packageTypeToTrackCategory } from '../../shared/utils';

export default {
  name: 'PackagesApp',
  components: {
    GlButton,
    GlEmptyState,
    GlLink,
    GlModal,
    GlTable,
    GlIcon,
    PackageInformation,
    PackageTags,
    NpmInstallation,
    MavenInstallation,
    ConanInstallation,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [timeagoMixin, Tracking.mixin()],
  trackingActions: { ...TrackingActions },
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
    files: {
      type: Array,
      default: () => [],
      required: true,
    },
    canDelete: {
      type: Boolean,
      default: false,
      required: true,
    },
    destroyPath: {
      type: String,
      default: '',
      required: true,
    },
    emptySvgPath: {
      type: String,
      required: true,
    },
    npmPath: {
      type: String,
      required: true,
    },
    npmHelpPath: {
      type: String,
      required: true,
    },
    mavenPath: {
      type: String,
      required: true,
    },
    mavenHelpPath: {
      type: String,
      required: true,
    },
    conanPath: {
      type: String,
      required: true,
    },
    conanHelpPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    isNpmPackage() {
      return this.packageEntity.package_type === PackageType.NPM;
    },
    isMavenPackage() {
      return this.packageEntity.package_type === PackageType.MAVEN;
    },
    isConanPackage() {
      return this.packageEntity.package_type === PackageType.CONAN;
    },
    isValidPackage() {
      return Boolean(this.packageEntity.name);
    },
    hasTagsToDisplay() {
      return Boolean(this.packageEntity.tags && this.packageEntity.tags.length);
    },
    canDeletePackage() {
      return this.canDelete && this.destroyPath;
    },
    deleteModalDescription() {
      return sprintf(
        s__(
          `PackageRegistry|You are about to delete version %{boldStart}%{version}%{boldEnd} of %{boldStart}%{name}%{boldEnd}. Are you sure?`,
        ),
        {
          version: _.escape(this.packageEntity.version),
          name: _.escape(this.packageEntity.name),
          boldStart: '<b>',
          boldEnd: '</b>',
        },
        false,
      );
    },
    packageInformation() {
      return generatePackageInfo(this.packageEntity);
    },
    packageMetadataTitle() {
      switch (this.packageEntity.package_type) {
        case PackageType.MAVEN:
          return s__('Maven Metadata');
        default:
          return s__('Package information');
      }
    },
    packageMetadata() {
      switch (this.packageEntity.package_type) {
        case PackageType.MAVEN:
          return [
            {
              label: s__('Group ID'),
              value: this.packageEntity.maven_metadatum.app_group,
            },
            {
              label: s__('Artifact ID'),
              value: this.packageEntity.maven_metadatum.app_name,
            },
            {
              label: s__('Version'),
              value: this.packageEntity.maven_metadatum.app_version,
            },
          ];
        default:
          return null;
      }
    },
    filesTableRows() {
      return this.files.map(x => ({
        name: x.file_name,
        downloadPath: x.download_path,
        size: this.formatSize(x.size),
        created: x.created_at,
      }));
    },
    tracking() {
      return {
        category: packageTypeToTrackCategory(this.packageEntity.package_type),
      };
    },
  },
  methods: {
    formatSize(size) {
      return numberToHumanSize(size);
    },
    cancelDelete() {
      this.$refs.deleteModal.hide();
    },
  },
  i18n: {
    deleteModalTitle: s__(`PackageRegistry|Delete Package Version`),
  },
  filesTableHeaderFields: [
    {
      key: 'name',
      label: __('Name'),
      tdClass: 'd-flex align-items-center',
    },
    {
      key: 'size',
      label: __('Size'),
    },
    {
      key: 'created',
      label: __('Created'),
      class: 'text-right',
    },
  ],
};
</script>

<template>
  <gl-empty-state
    v-if="!isValidPackage"
    :title="s__('PackageRegistry|Unable to load package')"
    :description="s__('PackageRegistry|There was a problem fetching the details for this package.')"
    :svg-path="emptySvgPath"
    class="js-package-empty-state"
  />

  <div v-else class="packages-app">
    <div class="detail-page-header d-flex justify-content-between">
      <div class="d-flex align-items-center">
        <gl-icon name="fork" class="append-right-8" />
        <strong class="append-right-default js-version-title">{{ packageEntity.version }}</strong>
        <package-tags v-if="hasTagsToDisplay" :tags="packageEntity.tags" />
      </div>
      <gl-button
        v-if="canDeletePackage"
        v-gl-modal="'delete-modal'"
        class="js-delete-button"
        variant="danger"
        data-qa-selector="delete_button"
        >{{ __('Delete') }}</gl-button
      >
    </div>

    <div class="row prepend-top-default" data-qa-selector="package_information_content">
      <div class="col-sm-6">
        <package-information :information="packageInformation" />
        <package-information
          v-if="packageMetadata"
          :heading="packageMetadataTitle"
          :information="packageMetadata"
          :show-copy="true"
        />
      </div>

      <div class="col-sm-6">
        <npm-installation
          v-if="isNpmPackage"
          :name="packageEntity.name"
          :registry-url="npmPath"
          :help-url="npmHelpPath"
        />

        <maven-installation
          v-else-if="isMavenPackage"
          :maven-metadata="packageEntity.maven_metadatum"
          :registry-url="mavenPath"
          :help-url="mavenHelpPath"
        />

        <conan-installation
          v-else-if="isConanPackage"
          :package-entity="packageEntity"
          :registry-url="conanPath"
          :help-url="conanHelpPath"
        />
      </div>
    </div>

    <gl-table
      :fields="$options.filesTableHeaderFields"
      :items="filesTableRows"
      tbody-tr-class="js-file-row"
    >
      <template #name="items">
        <gl-icon name="doc-code" class="space-right" />
        <gl-link
          :href="items.item.downloadPath"
          class="js-file-download"
          @click="track($options.trackingActions.PULL_PACKAGE)"
        >
          {{ items.item.name }}
        </gl-link>
      </template>

      <template #created="items">
        <span v-gl-tooltip :title="tooltipTitle(items.item.created)">{{
          timeFormatted(items.item.created)
        }}</span>
      </template>
    </gl-table>

    <gl-modal ref="deleteModal" class="js-delete-modal" modal-id="delete-modal">
      <template #modal-title>{{ $options.i18n.deleteModalTitle }}</template>
      <p v-html="deleteModalDescription"></p>

      <div slot="modal-footer" class="w-100">
        <div class="float-right">
          <gl-button @click="cancelDelete()">{{ __('Cancel') }}</gl-button>
          <gl-button
            ref="modal-delete-button"
            data-method="delete"
            :to="destroyPath"
            variant="danger"
            data-qa-selector="delete_modal_button"
            @click="track($options.trackingActions.DELETE_PACKAGE)"
            >{{ __('Delete') }}</gl-button
          >
        </div>
      </div>
    </gl-modal>
  </div>
</template>
