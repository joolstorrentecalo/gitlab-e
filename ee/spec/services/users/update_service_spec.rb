# frozen_string_literal: true
require 'spec_helper'

describe Users::UpdateService do
  let(:user) { create(:user) }

  describe '#execute' do
    context 'updating name' do
      let(:admin) { create(:admin) }

      shared_examples_for 'a user can update the name' do
        it 'updates the name' do
          result = described_class.new(current_user, { user: user, name: 'New Name' }).execute!

          expect(result).to be_truthy
          expect(user.name).to eq('New Name')
        end
      end

      context 'when `disable_name_update_for_users` feature is available' do
        before do
          stub_licensed_features(disable_name_update_for_users: true)
        end

        context 'when the ability to update their name is not disabled for users' do
          before do
            stub_application_setting(updating_name_disabled_for_users: false)
          end

          it_behaves_like 'a user can update the name' do
            let(:current_user) { user }
          end

          it_behaves_like 'a user can update the name' do
            let(:current_user) { admin }
          end
        end

        context 'when the ability to update their name is disabled for users' do
          before do
            stub_application_setting(updating_name_disabled_for_users: true)
          end

          context 'as a regular user' do
            it 'does not update the name' do
              result = update_user(user, name: 'New Name')

              expect(result).to be_truthy
              expect(user.name).not_to eq('New Name')
            end
          end

          it_behaves_like 'a user can update the name' do
            let(:current_user) { admin }
          end
        end
      end

      context 'when `disable_name_update_for_users` feature is not available' do
        before do
          stub_licensed_features(disable_name_update_for_users: false)
        end

        it_behaves_like 'a user can update the name' do
          let(:current_user) { user }
        end

        it_behaves_like 'a user can update the name' do
          let(:current_user) { admin }
        end
      end
    end

    it 'does not update email if an user has group managed account' do
      allow(user).to receive(:group_managed_account?).and_return(true)

      expect do
        update_user(user, { email: 'foreign@email' })
      end.not_to change { user.reload.email }
    end

    it 'does not update commit email if an user has group managed account' do
      allow(user).to receive(:group_managed_account?).and_return(true)

      expect do
        update_user(user, { commit_email: 'foreign@email' })
      end.not_to change { user.reload.commit_email }
    end

    it 'does not update public if an user has group managed account' do
      allow(user).to receive(:group_managed_account?).and_return(true)

      expect do
        update_user(user, { public_email: 'foreign@email' })
      end.not_to change { user.reload.public_email }
    end

    it 'does not update public if an user has group managed account' do
      allow(user).to receive(:group_managed_account?).and_return(true)

      expect do
        update_user(user, { notification_email: 'foreign@email' })
      end.not_to change { user.reload.notification_email }
    end

    context 'with an admin user' do
      let!(:admin_user) { create(:admin) }
      let(:service) { described_class.new(admin_user, ActionController::Parameters.new(params).permit!) }
      let(:params) do
        { name: 'John Doe', username: 'jduser', email: 'jd@example.com', password: 'mydummypass' }
      end

      context 'allowed params' do
        context 'with identity' do
          let(:provider) { create(:saml_provider) }
          let(:identity_params) { { extern_uid: 'uid', provider: 'group_saml', group_id_for_saml: provider.group.id } }

          before do
            params.merge!(identity_params)
          end

          it 'adds identity to user' do
            result = update_user(user, params)

            expect(result).to be true
            expect(user.identities.last.saml_provider_id).to eq(provider.id)
            expect(user.identities.last.extern_uid).to eq('uid')
            expect(user.identities.last.provider).to eq('group_saml')
          end

          it 'adds two different identities to user' do
            second_provider = create(:saml_provider)
            result_one = update_user(user, { extern_uid: 'uid', provider: 'group_saml', saml_provider_id: provider.id })
            result_two = update_user(user, { extern_uid: 'uid2', provider: 'group_saml', group_id_for_saml: second_provider.group.id } )

            expect(result_one).to be true
            expect(result_two).to be true
            expect(user.identities.count).to eq(2)
            expect(user.identities.map(&:extern_uid)).to match_array(%w(uid uid2))
            expect(user.identities.map(&:saml_provider_id)).to match_array([provider.id, second_provider.id])
          end
        end
      end
    end

    def update_user(user, opts)
      described_class.new(user, opts.merge(user: user)).execute!
    end
  end
end
