# frozen_string_literal: true

module ServiceDeskSettings
  class UpdateService < BaseService
    def execute
      settings = ServiceDeskSetting.safe_find_or_create_by!(project_id: project.id)

      if settings.update(params)
        success
      else
        error(settings.errors.full_messages.to_sentence)
      end
    end
  end
end
