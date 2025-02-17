# frozen_string_literal: true

module Operations
  class FeatureFlagsClient < ApplicationRecord
    include TokenAuthenticatable
    include IgnorableColumns

    self.table_name = 'operations_feature_flags_clients'
    ignore_column :token, remove_after: '2019-12-15', remove_with: '12.6'

    belongs_to :project

    validates :project, presence: true
    validates :token, presence: true

    add_authentication_token_field :token, encrypted: :required

    before_validation :ensure_token!

    def self.find_for_project_and_token(project, token)
      return unless project
      return unless token

      where(project_id: project).find_by_token(token)
    end
  end
end
