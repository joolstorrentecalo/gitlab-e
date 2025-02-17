# frozen_string_literal: true

module API
  class Epics < Grape::API
    include PaginationParams

    before do
      authenticate_non_get!
      authorize_epics_feature!
    end

    helpers ::API::Helpers::EpicsHelpers
    helpers ::Gitlab::IssuableMetadata

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get epics for the group' do
        success EE::API::Entities::Epic
      end
      params do
        optional :order_by, type: String, values: %w[created_at updated_at], default: 'created_at',
                            desc: 'Return epics ordered by `created_at` or `updated_at` fields.'
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
                        desc: 'Return epics sorted in `asc` or `desc` order.'
        optional :search, type: String, desc: 'Search epics for text present in the title or description'
        optional :state, type: String, values: %w[opened closed all], default: 'all',
                         desc: 'Return opened, closed, or all epics'
        optional :author_id, type: Integer, desc: 'Return epics which are authored by the user with the given ID'
        optional :labels, type: Array[String], coerce_with: Validations::Types::LabelsList.coerce, desc: 'Comma-separated list of label names'
        optional :with_labels_details, type: Boolean, desc: 'Return titles of labels and other details', default: false
        optional :created_after, type: DateTime, desc: 'Return epics created after the specified time'
        optional :created_before, type: DateTime, desc: 'Return epics created before the specified time'
        optional :updated_after, type: DateTime, desc: 'Return epics updated after the specified time'
        optional :updated_before, type: DateTime, desc: 'Return epics updated before the specified time'
        optional :include_ancestor_groups, type: Boolean, default: false, desc: 'Include epics from ancestor groups'
        optional :include_descendant_groups, type: Boolean, default: true, desc: 'Include epics from descendant groups'
        use :pagination
      end
      get ':id/(-/)epics' do
        epics = paginate(find_epics(finder_params: { group_id: user_group.id })).with_api_entity_associations

        # issuable_metadata is the standard used by the Todo API
        extra_options = { issuable_metadata: issuable_meta_data(epics, 'Epic'), with_labels_details: declared_params[:with_labels_details] }
        present epics, epic_options.merge(extra_options)
      end

      desc 'Get details of an epic' do
        success EE::API::Entities::Epic
      end
      params do
        requires :epic_iid, type: Integer, desc: 'The internal ID of an epic'
      end
      get ':id/(-/)epics/:epic_iid' do
        authorize_can_read!

        present epic, epic_options.merge(include_subscribed: true)
      end

      desc 'Create a new epic' do
        success EE::API::Entities::Epic
      end
      params do
        requires :title, type: String, desc: 'The title of an epic'
        optional :description, type: String, desc: 'The description of an epic'
        optional :start_date, as: :start_date_fixed, type: String, desc: 'The start date of an epic'
        optional :start_date_is_fixed, type: Boolean, desc: 'Indicates start date should be sourced from start_date_fixed field not the issue milestones'
        optional :end_date, as: :due_date_fixed, type: String, desc: 'The due date of an epic'
        optional :due_date_is_fixed, type: Boolean, desc: 'Indicates due date should be sourced from due_date_fixed field not the issue milestones'
        optional :labels, type: Array[String], coerce_with: Validations::Types::LabelsList.coerce, desc: 'Comma-separated list of label names'
        optional :parent_id, type: Integer, desc: 'The id of a parent epic'
      end
      post ':id/(-/)epics' do
        authorize_can_create!

        epic = ::Epics::CreateService.new(user_group, current_user, declared_params(include_missing: false)).execute
        if epic.valid?
          present epic, epic_options
        else
          render_validation_error!(epic)
        end
      end

      desc 'Update an epic' do
        success EE::API::Entities::Epic
      end
      params do
        requires :epic_iid, type: Integer, desc: 'The internal ID of an epic'
        optional :title, type: String, desc: 'The title of an epic'
        optional :description, type: String, desc: 'The description of an epic'
        optional :start_date, as: :start_date_fixed, type: String, desc: 'The start date of an epic'
        optional :start_date_is_fixed, type: Boolean, desc: 'Indicates start date should be sourced from start_date_fixed field not the issue milestones'
        optional :end_date, as: :due_date_fixed, type: String, desc: 'The due date of an epic'
        optional :due_date_is_fixed, type: Boolean, desc: 'Indicates due date should be sourced from due_date_fixed field not the issue milestones'
        optional :labels, type: Array[String], coerce_with: Validations::Types::LabelsList.coerce, desc: 'Comma-separated list of label names'
        optional :state_event, type: String, values: %w[reopen close], desc: 'State event for an epic'
        at_least_one_of :title, :description, :start_date_fixed, :start_date_is_fixed, :due_date_fixed, :due_date_is_fixed, :labels, :state_event
      end
      put ':id/(-/)epics/:epic_iid' do
        authorize_can_admin!
        update_params = declared_params(include_missing: false)
        update_params.delete(:epic_iid)

        result = ::Epics::UpdateService.new(user_group, current_user, update_params).execute(epic)

        if result.valid?
          present result, epic_options
        else
          render_validation_error!(result)
        end
      end

      desc 'Destroy an epic' do
        success EE::API::Entities::Epic
      end
      params do
        requires :epic_iid, type: Integer, desc: 'The internal ID of an epic'
      end
      delete ':id/(-/)epics/:epic_iid' do
        authorize_can_destroy!

        Issuable::DestroyService.new(nil, current_user).execute(epic)
      end
    end
  end
end
