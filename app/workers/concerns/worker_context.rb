# frozen_string_literal: true

module WorkerContext
  extend ActiveSupport::Concern

  class_methods do
    def worker_context(&block)
      @context_builder = block
    end

    def with_worker_context(*args, &block)
      return yield unless context_builder

      context_builder.call(*args).use(&block)
    end

    private

    attr_accessor :context_builder
  end
end
