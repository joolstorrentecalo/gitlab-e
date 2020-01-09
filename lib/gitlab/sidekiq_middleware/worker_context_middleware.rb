# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class WorkerContextMiddleware
      def call(worker_class, job, _queue, _redis_pool)
        klazz = worker_class.constantize

        return yield unless klazz.respond_to?(:with_worker_context)

        klazz.with_worker_context(*job['args']) do
          yield
        end
      end
    end
  end
end
