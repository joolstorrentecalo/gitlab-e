# frozen_string_literal: true

module DesignManagementTestHelpers
  def enable_design_management(enabled = true, ref_filter = true)
    stub_licensed_features(design_management: enabled)
    stub_lfs_setting(enabled: enabled)
    stub_feature_flags(design_management_reference_filter_gfm_pipeline: ref_filter)
  end

  def delete_designs(*designs)
    act_on_designs(designs) { ::DesignManagement::Action.deletion }
  end

  def restore_designs(*designs)
    act_on_designs(designs) { ::DesignManagement::Action.creation }
  end

  def modify_designs(*designs)
    act_on_designs(designs) { ::DesignManagement::Action.modification }
  end

  def path_for_design(design)
    path_options = { vueroute: design.filename }
    Gitlab::Routing.url_helpers.designs_project_issue_path(design.project, design.issue, path_options)
  end

  def url_for_design(design)
    path_options = { vueroute: design.filename }
    Gitlab::Routing.url_helpers.designs_project_issue_url(design.project, design.issue, path_options)
  end

  private

  def act_on_designs(designs, &block)
    issue = designs.first.issue
    version = build(:design_version, :empty, issue: issue).tap { |v| v.save(validate: false) }
    designs.each do |d|
      yield.create(design: d, version: version)
    end
    version
  end
end
