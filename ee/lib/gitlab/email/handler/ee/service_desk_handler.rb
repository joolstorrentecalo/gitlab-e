# frozen_string_literal: true

# handles service desk issue creation emails with these formats:
#   incoming+gitlab-org-gitlab-ce-20-issue-@incoming.gitlab.com
#   incoming+gitlab-org/gitlab-ce@incoming.gitlab.com (legacy)
module Gitlab
  module Email
    module Handler
      module EE
        class ServiceDeskHandler < BaseHandler
          include ReplyProcessing
          include Gitlab::Utils::StrongMemoize

          HANDLER_REGEX        = /\A#{HANDLER_ACTION_BASE_REGEX}-issue-\z/.freeze
          HANDLER_REGEX_LEGACY = /\A(?<project_path>[^\+]*)\z/.freeze

          def initialize(mail, mail_key)
            super(mail, mail_key)

            if !mail_key&.include?('/') && (matched = HANDLER_REGEX.match(mail_key.to_s))
              @project_slug = matched[:project_slug]
              @project_id   = matched[:project_id]&.to_i
            elsif matched = HANDLER_REGEX_LEGACY.match(mail_key.to_s)
              @project_path = matched[:project_path]
            end
          end

          def can_handle?
            ::EE::Gitlab::ServiceDesk.enabled? && (project_id || can_handle_legacy_format?)
          end

          def execute
            raise ProjectNotFound if project.nil?

            create_issue!
            send_thank_you_email! if from_address
          end

          def metrics_params
            super.merge(project: project&.full_path)
          end

          def metrics_event
            :receive_email_service_desk
          end

          private

          attr_reader :project_id, :project_path

          def project
            super

            @project = nil unless @project&.service_desk_enabled?
            @project
          end

          def create_issue!
            @issue = Issues::CreateService.new(
              project,
              User.support_bot,
              title: issue_title,
              description: message_including_template,
              confidential: true,
              service_desk_reply_to: from_address
            ).execute

            raise InvalidIssueError unless @issue.persisted?

            if service_desk_setting&.issue_template_missing?
              create_template_not_found_note(@issue)
            end
          end

          def send_thank_you_email!
            Notify.service_desk_thank_you_email(@issue.id).deliver_later!
          end

          def message_including_template
            description = message_including_reply
            template_content = service_desk_setting&.issue_template_content

            if template_content.present?
              description += "  \n" + template_content
            end

            description
          end

          def service_desk_setting
            strong_memoize(:service_desk_setting) do
              project.service_desk_setting
            end
          end

          def create_template_not_found_note(issue)
            issue_template_key = service_desk_setting&.issue_template_key

            warning_note = <<-MD.strip_heredoc
              WARNING: The template file #{issue_template_key}.md used for service desk issues is empty or could not be found.
              Please check service desk settings and update the file to be used.
            MD

            note_params = {
              noteable: issue,
              note: warning_note
            }

            ::Notes::CreateService.new(
              project,
              User.support_bot,
              note_params
            ).execute
          end

          def from_address
            (mail.reply_to || []).first || mail.from.first || mail.sender
          end

          def issue_title
            from = "(from #{from_address})" if from_address

            "Service Desk #{from}: #{mail.subject}"
          end

          def can_handle_legacy_format?
            project_path && project_path.include?('/') && !mail_key.include?('+')
          end

          def author
            User.support_bot
          end
        end
      end
    end
  end
end
