# frozen_string_literal: true

module Gitlab
  module Gpg
    class CommitSignatureLoader
      def initialize(commits, project)
        @commits = commits
        @project = project
      end

      def schedule_loading!
        return if commits_missing_signatures.empty?

        CreateGpgSignatureWorker.perform_async(commits_missing_signatures.map(&:sha), project.id)
      end

      def with_loaded_signatures
        @commits_loaded_signatures ||= commits.select { |commit| commit.signature.present? }
      end

      def commits_missing_signatures
        @commits_missing_signatures ||= commits.select { |commit| commit.has_signature? && commit.signature.nil? }
      end

      private

      attr_reader :commits, :project
    end
  end
end
