# frozen_string_literal: true

module Gitlab
  module Analytics
    module TypeOfWork
      class TasksByType
        LabelCountResult = Struct.new(:label, :series)

        FINDER_CLASSES = {
          MergeRequest.to_s => MergeRequestsFinder,
          Issue.to_s => IssuesFinder
        }.freeze

        def initialize(group:, params:, current_user:)
          @group = group
          @params = params
          @finder = finder_class.new(current_user, finder_params)
        end

        def counts_by_labels
          format_result(query_result)
        end

        private

        attr_reader :group, :params, :finder

        def finder_class
          FINDER_CLASSES.fetch(params[:subject], FINDER_CLASSES.keys.first)
        end

        def format_result(result)
          result.each_with_object({}) do |((label_id, date), count), hash|
            label = labels_by_id.fetch(label_id)

            hash[label_id] ||= LabelCountResult.new(label, [])
            hash[label_id].series << [date, count]
          end.values
        end

        def finder_params
          { include_subgroups: true, group_id: group.id }.merge(params.slice(:created_after, :created_before))
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def query_result
          finder
            .execute
            .joins(:label_links)
            .where(filters)
            .group(label_id_column, date_column)
            .reorder(nil)
            .count(subject_table[:id])
        end

        def filters
          {}.tap do |hash|
            hash[:label_links] = { label_id: labels_by_id.keys }
            hash[:project_id] = params[:project_ids] unless params[:project_ids].blank?
          end
        end

        def labels
          @labels ||= GroupLabel.where(id: params[:label_ids])
        end

        # rubocop: enable CodeReuse/ActiveRecord

        def label_id_column
          LabelLink.arel_table[:label_id]
        end

        # Generating `DATE(created_at)` string
        def date_column
          Arel::Nodes::NamedFunction.new('DATE', [subject_table[:created_at]]).to_sql
        end

        def subject_table
          finder.klass.arel_table
        end

        def labels_by_id
          @labels_by_id = labels.each_with_object({}) { |label, hash| hash[label.id] = label }
        end
      end
    end
  end
end
