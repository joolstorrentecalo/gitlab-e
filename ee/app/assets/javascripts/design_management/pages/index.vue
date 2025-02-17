<script>
import { GlLoadingIcon, GlEmptyState, GlButton } from '@gitlab/ui';
import createFlash from '~/flash';
import { s__, sprintf } from '~/locale';
import UploadButton from '../components/upload/button.vue';
import DeleteButton from '../components/delete_button.vue';
import Design from '../components/list/item.vue';
import DesignDestroyer from '../components/design_destroyer.vue';
import DesignVersionDropdown from '../components/upload/design_version_dropdown.vue';
import uploadDesignMutation from '../graphql/mutations/uploadDesign.mutation.graphql';
import permissionsQuery from '../graphql/queries/permissions.query.graphql';
import projectQuery from '../graphql/queries/project.query.graphql';
import allDesignsMixin from '../mixins/all_designs';
import { UPLOAD_DESIGN_ERROR, designDeletionError } from '../utils/error_messages';
import { updateStoreAfterUploadDesign } from '../utils/cache_update';
import { designUploadOptimisticResponse } from '../utils/design_management_utils';

const MAXIMUM_FILE_UPLOAD_LIMIT = 10;

export default {
  components: {
    GlLoadingIcon,
    UploadButton,
    GlEmptyState,
    GlButton,
    Design,
    DesignDestroyer,
    DesignVersionDropdown,
    DeleteButton,
  },
  mixins: [allDesignsMixin],
  apollo: {
    permissions: {
      query: permissionsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issueIid,
        };
      },
      update: data => data.project.issue.userPermissions,
    },
  },
  data() {
    return {
      permissions: {
        createDesign: false,
      },
      filesToBeSaved: [],
      selectedDesigns: [],
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.designs.loading || this.$apollo.queries.permissions.loading;
    },
    isSaving() {
      return this.filesToBeSaved.length > 0;
    },
    canCreateDesign() {
      return this.permissions.createDesign;
    },
    showToolbar() {
      return this.canCreateDesign && this.allVersions.length > 0;
    },
    hasDesigns() {
      return this.designs.length > 0;
    },
    hasSelectedDesigns() {
      return this.selectedDesigns.length > 0;
    },
    canDeleteDesigns() {
      return this.isLatestVersion && this.hasSelectedDesigns;
    },
    projectQueryBody() {
      return {
        query: projectQuery,
        variables: { fullPath: this.projectPath, iid: this.issueIid, atVersion: null },
      };
    },
    selectAllButtonText() {
      return this.hasSelectedDesigns
        ? s__('DesignManagement|Deselect all')
        : s__('DesignManagement|Select all');
    },
  },
  methods: {
    resetFilesToBeSaved() {
      this.filesToBeSaved = [];
    },
    /**
     * Determine if a design upload is valid, given [files]
     * @param {Array<File>} files
     */
    isValidDesignUpload(files) {
      if (!this.canCreateDesign) return false;

      if (files.length > MAXIMUM_FILE_UPLOAD_LIMIT) {
        createFlash(
          sprintf(
            s__(
              'DesignManagement|The maximum number of designs allowed to be uploaded is %{upload_limit}. Please try again.',
            ),
            {
              upload_limit: MAXIMUM_FILE_UPLOAD_LIMIT,
            },
          ),
        );

        return false;
      }
      return true;
    },
    onUploadDesign(files) {
      // convert to Array so that we have Array methods (.map, .some, etc.)
      this.filesToBeSaved = Array.from(files);
      if (!this.isValidDesignUpload(this.filesToBeSaved)) return null;

      const mutationPayload = {
        optimisticResponse: designUploadOptimisticResponse(this.filesToBeSaved),
        variables: {
          files: this.filesToBeSaved,
          projectPath: this.projectPath,
          iid: this.issueIid,
        },
        context: {
          hasUpload: true,
        },
        mutation: uploadDesignMutation,
        update: this.afterUploadDesign,
      };

      return this.$apollo
        .mutate(mutationPayload)
        .then(() => this.onUploadDesignDone())
        .catch(() => this.onUploadDesignError());
    },
    afterUploadDesign(
      store,
      {
        data: { designManagementUpload },
      },
    ) {
      updateStoreAfterUploadDesign(store, designManagementUpload, this.projectQueryBody);
    },
    onUploadDesignDone() {
      this.resetFilesToBeSaved();
      this.$router.push({ name: 'designs' });
    },
    onUploadDesignError() {
      this.resetFilesToBeSaved();
      createFlash(UPLOAD_DESIGN_ERROR);
    },
    changeSelectedDesigns(filename) {
      if (this.isDesignSelected(filename)) {
        this.selectedDesigns = this.selectedDesigns.filter(design => design !== filename);
      } else {
        this.selectedDesigns.push(filename);
      }
    },
    toggleDesignsSelection() {
      if (this.hasSelectedDesigns) {
        this.selectedDesigns = [];
      } else {
        this.selectedDesigns = this.designs.map(design => design.filename);
      }
    },
    isDesignSelected(filename) {
      return this.selectedDesigns.includes(filename);
    },
    isDesignToBeSaved(filename) {
      return this.filesToBeSaved.some(file => file.name === filename);
    },
    canSelectDesign(filename) {
      return this.isLatestVersion && this.canCreateDesign && !this.isDesignToBeSaved(filename);
    },
    onDesignDelete() {
      this.selectedDesigns = [];
      if (this.$route.query.version) this.$router.push({ name: 'designs' });
    },
    onDesignDeleteError() {
      const errorMessage = designDeletionError({ singular: this.selectedDesigns.length === 1 });
      createFlash(errorMessage);
    },
  },
  beforeRouteUpdate(to, from, next) {
    this.selectedDesigns = [];
    next();
  },
};
</script>

<template>
  <div>
    <header v-if="showToolbar" class="row-content-block border-top-0 p-2 d-flex">
      <div class="d-flex justify-content-between align-items-center w-100">
        <design-version-dropdown />
        <div :class="['qa-selector-toolbar', { 'd-flex': hasDesigns, 'd-none': !hasDesigns }]">
          <gl-button
            v-if="isLatestVersion"
            variant="link"
            class="mr-2 js-select-all"
            @click="toggleDesignsSelection"
            >{{ selectAllButtonText }}</gl-button
          >
          <design-destroyer
            v-slot="{ mutate, loading }"
            :filenames="selectedDesigns"
            :project-path="projectPath"
            :iid="issueIid"
            @done="onDesignDelete"
            @error="onDesignDeleteError"
          >
            <delete-button
              v-if="isLatestVersion"
              :is-deleting="loading"
              button-class="btn-danger btn-inverted mr-2"
              :has-selected-designs="hasSelectedDesigns"
              @deleteSelectedDesigns="mutate()"
            >
              {{ s__('DesignManagement|Delete selected') }}
              <gl-loading-icon v-if="loading" inline class="ml-1" />
            </delete-button>
          </design-destroyer>
          <upload-button v-if="canCreateDesign" :is-saving="isSaving" @upload="onUploadDesign" />
        </div>
      </div>
    </header>
    <div class="mt-4">
      <gl-loading-icon v-if="isLoading" size="md" />
      <div v-else-if="error" class="alert alert-danger">
        {{ __('An error occurred while loading designs. Please try again.') }}
      </div>
      <ol v-else-if="hasDesigns" class="list-unstyled row">
        <li v-for="design in designs" :key="design.id" class="col-md-6 col-lg-4 mb-3">
          <design v-bind="design" :is-loading="isDesignToBeSaved(design.filename)" />
          <input
            v-if="canSelectDesign(design.filename)"
            :checked="isDesignSelected(design.filename)"
            type="checkbox"
            class="design-checkbox"
            @change="changeSelectedDesigns(design.filename)"
          />
        </li>
      </ol>
      <gl-empty-state
        v-else
        :title="s__('DesignManagement|The one place for your designs')"
        :description="
          s__(`DesignManagement|Upload and view the latest designs for this issue.
            Consistent and easy to find, so everyone is up to date.`)
        "
      >
        <template #actions>
          <div v-if="canCreateDesign" class="center">
            <upload-button :is-saving="isSaving" @upload="onUploadDesign" />
          </div>
        </template>
      </gl-empty-state>
    </div>
    <router-view />
  </div>
</template>
