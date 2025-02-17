# frozen_string_literal: true

module EE
  module Emails
    module Notes
      def note_epic_email(recipient_id, note_id, reason = nil)
        setup_note_mail(note_id, recipient_id)

        @epic = @note.noteable
        @target_url = group_epic_url(*note_target_url_options)
        mail_answer_note_thread(@epic, @note, note_thread_options(recipient_id, reason))
      end

      def note_design_email(recipient_id, note_id, reason = nil)
        setup_note_mail(note_id, recipient_id)

        design = @note.noteable
        @target_url = ::Gitlab::Routing.url_helpers.designs_project_issue_url(
          @note.resource_parent,
          design.issue,
          note_target_url_query_params.merge(vueroute: design.filename)
        )
        mail_answer_note_thread(design, @note, note_thread_options(recipient_id, reason))
      end
    end
  end
end
