# frozen_string_literal: true

require 'spec_helper'

describe API::Members do
  let(:group) { create(:group) }
  let(:owner) { create(:user) }
  let(:project) { create(:project, group: group) }

  before do
    group.add_owner(owner)
  end

  describe 'POST /projects/:id/members' do
    context 'group membership locked' do
      let(:user) { create(:user) }
      let(:group) { create(:group, membership_lock: true)}
      let(:project) { create(:project, group: group) }

      context 'project in a group' do
        it 'returns a 405 method not allowed error when group membership lock is enabled' do
          post api("/projects/#{project.id}/members", owner),
               params: { user_id: user.id, access_level: Member::MAINTAINER }

          expect(response.status).to eq 405
        end
      end
    end
  end

  describe 'GET /groups/:id/members' do
    context 'when a group has SAML provider configured' do
      let(:maintainer) { create(:user) }

      before do
        saml_provider = create :saml_provider, group: group
        create :group_saml_identity, user: owner, saml_provider: saml_provider

        group.add_maintainer(maintainer)
      end

      context 'and current_user is group owner' do
        it 'returns a list of users with group SAML identities info' do
          get api("/groups/#{group.to_param}/members", owner)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response.size).to eq(2)
          expect(json_response.first['group_saml_identity']).to match(kind_of(Hash))
        end

        it 'allows to filter by linked identity presence' do
          get api("/groups/#{group.to_param}/members?with_saml_identity=true", owner)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response.size).to eq(1)
          expect(json_response.any? { |member| member['id'] == maintainer.id }).to be_falsey
        end
      end

      context 'and current_user is not an owner' do
        it 'returns a list of users without group SAML identities info' do
          get api("/groups/#{group.to_param}/members", maintainer)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response.map(&:keys).flatten).not_to include('group_saml_identity')
        end

        it 'ignores filter by linked identity presence' do
          get api("/groups/#{group.to_param}/members?with_saml_identity=true", maintainer)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response.size).to eq(2)
          expect(json_response.any? { |member| member['id'] == maintainer.id }).to be_truthy
        end
      end
    end
  end

  shared_examples 'POST /:source_type/:id/members' do |source_type|
    let(:stranger) { create(:user) }
    let(:url) { "/#{source_type.pluralize}/#{source.id}/members" }

    context "with :source_type == #{source_type.pluralize}" do
      it 'creates an audit event while creating a new member' do
        params = { user_id: stranger.id, access_level: Member::DEVELOPER }

        expect do
          post api(url, owner), params: params

          expect(response).to have_gitlab_http_status(201)
        end.to change { AuditEvent.count }.by(1)
      end

      it 'does not create audit event if creating a new member fails' do
        params = { user_id: 0, access_level: Member::DEVELOPER }

        expect do
          post api(url, owner), params: params

          expect(response).to have_gitlab_http_status(404)
        end.not_to change { AuditEvent.count }
      end
    end
  end

  it_behaves_like 'POST /:source_type/:id/members', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'POST /:source_type/:id/members', 'group' do
    let(:source) { group }
  end
end
