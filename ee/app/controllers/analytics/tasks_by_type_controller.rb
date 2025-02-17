# frozen_string_literal: true

class Analytics::TasksByTypeController < Analytics::ApplicationController
  check_feature_flag Gitlab::Analytics::TASKS_BY_TYPE_CHART_FEATURE_FLAG

  before_action :load_group
  before_action -> { check_feature_availability!(:type_of_work_analytics) }
  before_action -> { authorize_view_by_action!(:view_type_of_work_charts) }
  before_action :validate_label_ids
  before_action :prepare_date_range

  def show
    render json: Analytics::TasksByTypeLabelEntity.represent(counts_by_labels)
  end

  private

  def counts_by_labels
    Gitlab::Analytics::TypeOfWork::TasksByType.new(group: @group, current_user: current_user, params: {
      subject: params[:subject],
      label_ids: Array(params[:label_ids]),
      project_ids: Array(params[:project_ids]),
      created_after: @created_after.to_time.utc.beginning_of_day,
      created_before: @created_before.to_time.utc.end_of_day
    }).counts_by_labels
  end

  def validate_label_ids
    return respond_422 if Array(params[:label_ids]).empty?
  end

  def prepare_date_range
    @created_after = parse_date(params[:created_after])
    return respond_422 unless @created_after

    @created_before = parse_date(params[:created_before]) || Date.today

    return respond_422 if @created_after > @created_before
  end

  def parse_date(value)
    return unless value

    Date.parse(value)
  rescue ArgumentError
  end
end
