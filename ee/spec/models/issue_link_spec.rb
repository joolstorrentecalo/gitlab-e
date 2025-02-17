# frozen_string_literal: true

require 'spec_helper'

describe IssueLink do
  describe 'Associations' do
    it { is_expected.to belong_to(:source).class_name('Issue') }
    it { is_expected.to belong_to(:target).class_name('Issue') }
  end

  describe 'link_type' do
    it { is_expected.to define_enum_for(:link_type).with_values(relates_to: 0, blocks: 1, is_blocked_by: 2) }

    it 'provides the "related" as default link_type' do
      expect(create(:issue_link).link_type).to eq 'relates_to'
    end
  end

  describe 'Validation' do
    subject { create :issue_link }

    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:target) }
    it do
      is_expected.to validate_uniqueness_of(:source)
        .scoped_to(:target_id)
        .with_message(/already related/)
    end

    context 'self relation' do
      let(:issue) { create :issue }

      context 'cannot be validated' do
        it 'does not invalidate object with self relation error' do
          issue_link = build :issue_link, source: issue, target: nil

          issue_link.valid?

          expect(issue_link.errors[:source]).to be_empty
        end
      end

      context 'can be invalidated' do
        it 'invalidates object' do
          issue_link = build :issue_link, source: issue, target: issue

          expect(issue_link).to be_invalid
          expect(issue_link.errors[:source]).to include('cannot be related to itself')
        end
      end
    end
  end

  describe '.inverse_link_type' do
    it 'returns reverse type of link' do
      expect(described_class.inverse_link_type('relates_to')).to eq 'relates_to'
      expect(described_class.inverse_link_type('blocks')).to eq 'is_blocked_by'
      expect(described_class.inverse_link_type('is_blocked_by')).to eq 'blocks'
    end
  end
end
