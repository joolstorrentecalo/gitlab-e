# frozen_string_literal: true

module RuboCop
  module Cop
    module Scalability
      class BulkPerformWithContext < RuboCop::Cop::Cop
        MSG = <<~MSG.freeze
          Prefer using `Worker.bulk_perform_async_with_contexts` and
          `Worker.bulk_perform_in_with_context` over the methods without a context
          if your worker deals with specific projects or namespaces
          The context is required to add metadata to our logs.

          Read more about it https://docs.gitlab.com/ee/development/sidekiq_style_guide.html#worker-context
        MSG

        def_node_matcher :schedules_in_batch_without_context?, <<~PATTERN
          (send (...) {:bulk_perform_async :bulk_perform_in} (...))
        PATTERN

        def on_send(node)
          return unless schedules_in_batch_without_context?(node)

          add_offense(node, location: :expression)
        end
      end
    end
  end
end
