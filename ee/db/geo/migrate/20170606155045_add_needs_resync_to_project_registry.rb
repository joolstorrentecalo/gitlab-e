class AddNeedsResyncToProjectRegistry < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/AddColumnWithDefault
    add_column_with_default(:project_registry, :resync_repository, :boolean, default: true)
    add_column_with_default(:project_registry, :resync_wiki, :boolean, default: true)
    # rubocop:enable Migration/AddColumnWithDefault
  end

  def down
    remove_columns :project_registry, :resync_repository, :resync_wiki
  end
end
