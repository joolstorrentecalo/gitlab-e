# frozen_string_literal: true

# Concern that sets various Sidekiq settings for workers executed using a
# cronjob.
module CronjobQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :cronjob
    sidekiq_options retry: false

    # Start the Cronjob worker with an empty context. This can be overridden in
    # the worker implementing this module.
    worker_context do |*args|
      # TODO, we could add that the job is triggered by a cron here, I think that
      # would belong in the `caller_id` that we're still building
      Gitlab::ApplicationContext.new(user: nil, namespace: nil, project: nil)
    end
  end
end
