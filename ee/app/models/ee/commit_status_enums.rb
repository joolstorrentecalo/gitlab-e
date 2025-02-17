# frozen_string_literal: true

module EE
  module CommitStatusEnums
    extend ActiveSupport::Concern

    class_methods do
      extend ::Gitlab::Utils::Override

      override :failure_reasons
      def failure_reasons
        super.merge(protected_environment_failure: 1_000,
                    insufficient_bridge_permissions: 1_001,
                    downstream_bridge_project_not_found: 1_002,
                    invalid_bridge_trigger: 1_003,
                    upstream_bridge_project_not_found: 1_004,
                    insufficient_upstream_permissions: 1_005,
                    bridge_pipeline_is_child_pipeline: 1_006)
      end
    end
  end
end
