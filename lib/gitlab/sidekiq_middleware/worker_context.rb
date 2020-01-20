# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module WorkerContext
      class Server
        include SidekiqMiddleware::WorkerContext

        def call(worker, job, _queue, &block)
          worker_class = worker.class

          # This is not a worker we know about, perhaps from a gem
          return yield unless worker_class.include?(ApplicationWorker)

          # Use the context defined on the class level as a base context
          wrap_in_context(worker_class.get_worker_context, &block)
        end
      end

      private

      def wrap_in_optional_context(context_or_nil, &block)
        return yield unless context_or_nil

        context_or_nil.use(&block)
      end
    end
  end
end
