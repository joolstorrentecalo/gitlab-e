# frozen_string_literal: true

module Gitlab
  module Insights
    module Finders
      class IssuableFinder
        include Gitlab::Utils::StrongMemoize

        IssuableFinderError = Class.new(StandardError)
        InvalidIssuableTypeError = Class.new(IssuableFinderError)
        InvalidGroupByError = Class.new(IssuableFinderError)
        InvalidPeriodLimitError = Class.new(IssuableFinderError)
        InvalidEntityError = Class.new(IssuableFinderError)

        FINDERS = {
          issue: ::IssuesFinder,
          merge_request: ::MergeRequestsFinder
        }.with_indifferent_access.freeze
        PERIODS = {
          days: { default: 30 },
          weeks: { default: 12 },
          months: { default: 12 }
        }.with_indifferent_access.freeze

        def initialize(entity, current_user, query: {}, projects: {})
          @entity = entity
          @current_user = current_user
          @query = query
          @projects = projects
        end

        # Returns an Active Record relation of issuables.
        def find
          return unless entity_args

          relation = finder
            .new(current_user, finder_args)
            .execute
          relation = relation.preload(:labels) if query.key?(:collection_labels) # rubocop:disable CodeReuse/ActiveRecord

          relation
        end

        def period_limit
          @period_limit ||=
            if query.key?(:period_limit)
              begin
                Integer(query[:period_limit])
              rescue ArgumentError
                raise InvalidPeriodLimitError, "Invalid `:period_limit` option: `#{query[:period_limit]}`. Expected an integer!"
              end
            else
              PERIODS.dig(period, :default)
            end
        end

        private

        attr_reader :entity, :current_user, :query, :projects

        def finder
          issuable_type = query[:issuable_type]&.to_sym

          FINDERS[issuable_type] ||
            raise(InvalidIssuableTypeError, "Invalid `:issuable_type` option: `#{query[:issuable_type]}`. Allowed values are #{FINDERS.keys}!")
        end

        def finder_args
          {
            include_subgroups: true,
            state: query[:issuable_state] || 'opened',
            label_name: query[:filter_labels],
            sort: 'created_asc',
            created_after: created_after_argument
          }.merge(entity_args)
        end

        def entity_args
          strong_memoize(:entity_args) do
            case entity
            when ::Project
              if finder_projects
                { project_id: entity.id } if finder_projects.exists?(entity.id) # rubocop: disable CodeReuse/ActiveRecord
              else
                { project_id: entity.id }
              end
            when ::Namespace
              { group_id: entity.id, projects: finder_projects }
            else
              raise InvalidEntityError, "Entity class `#{entity.class}` is not supported. Supported classes are Project and Namespace!"
            end
          end
        end

        def created_after_argument
          return unless query.key?(:group_by)

          Time.zone.now.advance(period => -period_limit)
        end

        def period
          @period ||=
            if query.key?(:group_by)
              period = query[:group_by].to_s.pluralize.to_sym

              unless PERIODS.key?(period)
                raise InvalidGroupByError, "Invalid `:group_by` option: `#{query[:group_by]}`. Allowed values are #{PERIODS.keys}!"
              end

              period
            else
              :days
            end
        end

        def finder_projects
          strong_memoize(:finder_projects) do
            if projects.empty?
              nil
            elsif finder_projects_options[:ids] && finder_projects_options[:paths]
              Project.from_union([finder_projects_ids, finder_projects_paths])
            elsif finder_projects_options[:ids]
              finder_projects_ids
            elsif finder_projects_options[:paths]
              finder_projects_paths
            end
          end
        end

        def finder_projects_ids
          Project.id_in(finder_projects_options[:ids]).select(:id)
        end

        def finder_projects_paths
          Project.where_full_path_in(
            finder_projects_options[:paths], use_includes: false
          ).select(:id)
        end

        def finder_projects_options
          @finder_projects_options ||= projects[:only]&.group_by do |item|
            case item
            when Integer
              :ids
            when String
              :paths
            else
              :unknown
            end
          end || {}
        end
      end
    end
  end
end
