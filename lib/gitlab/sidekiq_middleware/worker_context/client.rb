# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module WorkerContext
      class Client
        include Gitlab::SidekiqMiddleware::WorkerContext

        def call(worker_class_or_name, job, _queue, _redis_pool, &block)
          worker_class = constantize_worker(worker_class_or_name)
          # Mailers can't be constantized like this
          return yield unless worker_class

          context_for_args = worker_class.context_for_arguments(job['args'])

          wrap_in_optional_context(context_for_args, &block)
        end

        private

        def constantize_worker(class_name)
          class_name.to_s.constantize
        rescue NameError
          nil
        end
      end
    end
  end
end
