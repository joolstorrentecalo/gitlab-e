# frozen_string_literal: true

require 'spec_helper'

describe LinkedProjectIssueEntity do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:issue_link) { create(:issue_link) }

  let(:request) { double('request') }
  let(:related_issue) { issue_link.source.related_issues(user).first }
  let(:entity) { described_class.new(related_issue, request: request, current_user: user) }

  before do
    allow(request).to receive(:current_user).and_return(user)
    allow(request).to receive(:issuable).and_return(issue_link.source)
    issue_link.target.project.add_developer(user)
  end

  describe 'issue_link_type' do
    context 'when issue_link_types is enabled' do
      before do
        stub_feature_flags(issue_link_types: true)
      end

      it { expect(entity.as_json).to include(link_type: 'relates_to') }
    end

    context 'when issue_link_types is disabled' do
      before do
        stub_feature_flags(issue_link_types: false)
      end

      it { expect(entity.as_json).not_to include(:link_type) }
    end

    context 'when issue_link_types is not enabled for target issue project' do
      before do
        stub_feature_flags(issue_link_types: { thing: issue_link.target.project, enabled: false })
      end

      it { expect(entity.as_json).to include(link_type: 'relates_to') }
    end

    context 'when issue_link_types is not enabled for source issue project' do
      before do
        stub_feature_flags(issue_link_types: { thing: issue_link.source.project, enabled: false })
      end

      it { expect(entity.as_json).not_to include(:link_type) }
    end
  end
end
