# frozen_string_literal: true

module WorkerContext
  extend ActiveSupport::Concern

  class_methods do
    def bulk_perform_async_with_contexts(contexts_for_arguments)
      with_batch_contexts(contexts_for_arguments) do
        bulk_perform_async(contexts_for_arguments.keys)
      end
    end

    def bulk_perform_in_with_contexts(delay, contexts_for_arguments)
      with_batch_contexts(contexts_for_arguments) do
        bulk_perform_in(delay, contexts_for_arguments.keys)
      end
    end

    def worker_context(attributes)
      @worker_context = Gitlab::ApplicationContext.new(attributes)
    end

    def get_worker_context
      @worker_context
    end

    def context_for_arguments(args)
      batch_scheduling_contexts[args]
    end

    private

    def batch_scheduling_contexts
      Thread.current["#{name}_batch_scheduling_contexts"] ||= {}
    end

    def with_batch_contexts(contexts_for_atributes)
      contexts = contexts_for_atributes.transform_values do |info|
        Gitlab::ApplicationContext.new(info)
      end
      batch_scheduling_contexts.merge!(contexts)

      yield
    ensure
      batch_scheduling_contexts.clear
    end
  end

  def with_context(context, &block)
    Gitlab::ApplicationContext.new(context).use(&block)
  end
end
