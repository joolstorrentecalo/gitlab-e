# frozen_string_literal: true

require 'spec_helper'

describe ApprovalWrappedAnyApproverRule do
  let(:merge_request) { create(:merge_request) }

  subject { described_class.new(merge_request, rule) }

  let(:rule) do
    create(:any_approver_rule, merge_request: merge_request, approvals_required: 2)
  end

  let(:approver1) { create(:user) }
  let(:approver2) { create(:user) }

  before do
    create(:approval, merge_request: merge_request, user: approver1)
    create(:approval, merge_request: merge_request, user: approver2)
  end

  context '#approvals_approvers' do
    it 'contains every approved user' do
      expect(subject.approved_approvers).to contain_exactly(approver1, approver2)
    end

    context 'when an author and a committer approved' do
      before do
        merge_request.project.update!(
          merge_requests_author_approval: false,
          merge_requests_disable_committers_approval: true
        )

        create(:approval, merge_request: merge_request, user: merge_request.author)

        committer = create(:user, username: 'commiter')
        create(:approval, merge_request: merge_request, user: committer)
        allow(merge_request).to receive(:committers).and_return(User.where(id: committer.id))
      end

      it 'does not contain an author' do
        expect(subject.approved_approvers).to contain_exactly(approver1, approver2)
      end
    end
  end

  it '#approved?' do
    expect(subject.approved?).to eq(true)
  end
end
