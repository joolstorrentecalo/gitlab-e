# frozen_string_literal: true

require 'spec_helper'

describe UsersHelper do
  let(:user) { create(:user) }

  describe '#current_user_menu_items' do
    using RSpec::Parameterized::TableSyntax

    where(
      has_paid_namespace?: [true, false],
      user?: [true, false],
      gitlab_com?: [true, false],
      user_eligible?: [true, false]
    )

    with_them do
      before do
        allow(helper).to receive(:current_user) { user? ? user : nil }
        allow(helper).to receive(:can?).and_return(false)

        allow(::Gitlab).to receive(:com?) { gitlab_com? }
        allow(user).to receive(:any_namespace_without_trial?) { user_eligible? }
        allow(user).to receive(:has_paid_namespace?) { has_paid_namespace? }
      end

      let(:expected_result) { !has_paid_namespace? && user? && gitlab_com? && user_eligible? }

      subject { helper.current_user_menu_items.include?(:start_trial) }

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#user_badges_in_admin_section' do
    subject { helper.user_badges_in_admin_section(user) }

    before do
      allow(helper).to receive(:current_user).and_return(build(:user))
    end

    context 'with user who is using a license seat' do
      before do
        allow(user).to receive(:using_license_seat?).and_return(true)
      end

      context 'when user is an admin and the current_user' do
        before do
          allow(helper).to receive(:current_user).and_return(user)
          allow(user).to receive(:admin?).and_return(true)
        end

        it do
          expect(subject).to eq(
            [
              { text: 'Admin', variant: 'success' },
              { text: 'Is using seat', variant: 'light' },
              { text: "It's you!", variant: nil }
            ]
          )
        end
      end

      it { expect(subject).to eq([text: 'Is using seat', variant: 'light']) }
    end

    context 'with user who is not using a license seat' do
      before do
        allow(user).to receive(:using_license_seat?).and_return(false)
      end

      it { expect(subject).to eq([]) }
    end
  end
end
