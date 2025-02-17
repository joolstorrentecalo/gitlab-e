# frozen_string_literal: true

module DesignManagement
  class DesignsFinder
    include Gitlab::Allowable

    # Params:
    # ids: integer[]
    # visible_at_version: ?version
    def initialize(issue, current_user, params = {})
      @issue = issue
      @current_user = current_user
      @params = params
    end

    def execute
      items = init_collection

      items = by_visible_at_version(items)
      items = by_filename(items)
      items = by_id(items)

      items
    end

    private

    attr_reader :issue, :current_user, :params

    def init_collection
      return ::DesignManagement::Design.none unless can?(current_user, :read_design, issue)

      issue.designs
    end

    # Returns all designs that existed at a particular design version
    def by_visible_at_version(items)
      items.visible_at_version(params[:visible_at_version])
    end

    def by_filename(items)
      return items unless params[:filenames].present?

      items.with_filename(params[:filenames])
    end

    def by_id(items)
      return items unless params[:ids].present?

      items.id_in(params[:ids])
    end
  end
end
