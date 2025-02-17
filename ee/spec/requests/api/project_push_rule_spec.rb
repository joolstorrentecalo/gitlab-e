# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectPushRule, 'ProjectPushRule', api: true do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:user3) { create(:user) }
  let!(:project) { create(:project, :repository, creator_id: user.id, namespace: user.namespace) }

  before do
    stub_licensed_features(push_rules: push_rules_enabled,
                           commit_committer_check: ccc_enabled,
                           reject_unsigned_commits: ruc_enabled)
    project.add_maintainer(user)
    project.add_developer(user3)
  end

  let(:push_rules_enabled) { true }
  let(:ccc_enabled) { true }
  let(:ruc_enabled) { true }

  describe "GET /projects/:id/push_rule" do
    before do
      create(:push_rule, project: project, **attributes)
    end

    let(:attributes) do
      { commit_committer_check: true }
    end

    context "authorized user" do
      before do
        get api("/projects/#{project.id}/push_rule", user)
      end

      it "returns project push rule" do
        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Hash
        expect(json_response['project_id']).to eq(project.id)
      end

      context 'the commit_committer_check feature is enabled' do
        let(:ccc_enabled) { true }

        it 'returns the commit_committer_check information' do
          subset = attributes
            .slice(:commit_committer_check)
            .transform_keys(&:to_s)
          expect(json_response).to include(subset)
        end
      end

      context 'the reject_unsigned_commits feature is enabled' do
        let(:ruc_enabled) { true }

        it 'returns the reject_unsigned_commits information' do
          subset = attributes
            .slice(:reject_unsigned_commits)
            .transform_keys(&:to_s)
          expect(json_response).to include(subset)
        end
      end

      context 'the reject_unsigned_commits feature is not enabled' do
        let(:ruc_enabled) { false }

        it 'succeeds' do
          expect(response).to have_gitlab_http_status(200)
        end

        it 'does not return the reject_unsigned_commits information' do
          expect(json_response).not_to have_key('reject_unsigned_commits')
        end
      end

      context 'push rules are not enabled' do
        let(:push_rules_enabled) { false }

        it 'is forbidden' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context "developer" do
      it "does not have access to project push rule" do
        get api("/projects/#{project.id}/push_rule", user3)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe "POST /projects/:id/push_rule" do
    let(:rules_params) do
      { deny_delete_tag: true,
        member_check: true,
        prevent_secrets: true,
        commit_message_regex: 'JIRA\-\d+',
        branch_name_regex: '(feature|hotfix)\/*',
        author_email_regex: '[a-zA-Z0-9]+@gitlab.com',
        file_name_regex: '[a-zA-Z0-9]+.key',
        max_file_size: 5,
        commit_committer_check: true,
        reject_unsigned_commits: true }
    end

    let(:expected_response) do
      rules_params.transform_keys(&:to_s)
    end

    context "maintainer" do
      before do
        post api("/projects/#{project.id}/push_rule", user), params: rules_params
      end

      context 'commit_committer_check not allowed by License' do
        let(:ccc_enabled) { false }

        it "is forbidden to use this service" do
          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'reject_unsigned_commits not allowed by License' do
        let(:ruc_enabled) { false }

        it "is forbidden to use this service" do
          expect(response).to have_gitlab_http_status(403)
        end
      end

      it "is accepted" do
        expect(response).to have_gitlab_http_status(201)
      end

      it "indicates that it belongs to the correct project" do
        expect(json_response['project_id']).to eq(project.id)
      end

      it "sets all given parameters" do
        expect(json_response).to include(expected_response)
      end

      context 'commit_committer_check is not enabled' do
        let(:ccc_enabled) { false }

        it "is forbidden to send the the :commit_committer_check parameter" do
          expect(response).to have_gitlab_http_status(403)
        end

        context "without the :commit_committer_check parameter" do
          let(:rules_params) do
            { deny_delete_tag: true,
              member_check: true,
              prevent_secrets: true,
              commit_message_regex: 'JIRA\-\d+',
              branch_name_regex: '(feature|hotfix)\/*',
              author_email_regex: '[a-zA-Z0-9]+@gitlab.com',
              file_name_regex: '[a-zA-Z0-9]+.key',
              max_file_size: 5 }
          end

          it "sets all given parameters" do
            expect(json_response).to include(expected_response)
          end
        end
      end

      context 'reject_unsigned_commits is not enabled' do
        let(:ruc_enabled) { false }

        it "is forbidden to send the the :reject_unsigned_commits parameter" do
          expect(response).to have_gitlab_http_status(403)
        end

        context "without the :reject_unsigned_commits parameter" do
          let(:rules_params) do
            { deny_delete_tag: true,
              member_check: true,
              prevent_secrets: true,
              commit_message_regex: 'JIRA\-\d+',
              branch_name_regex: '(feature|hotfix)\/*',
              author_email_regex: '[a-zA-Z0-9]+@gitlab.com',
              file_name_regex: '[a-zA-Z0-9]+.key',
              max_file_size: 5 }
          end

          it "sets all given parameters" do
            expect(json_response).to include(expected_response)
          end
        end
      end
    end

    it 'adds push rule to project with no file size' do
      post api("/projects/#{project.id}/push_rule", user),
        params: { commit_message_regex: 'JIRA\-\d+' }

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['project_id']).to eq(project.id)
      expect(json_response['commit_message_regex']).to eq('JIRA\-\d+')
      expect(json_response['max_file_size']).to eq(0)
    end

    it 'returns 400 if no parameter is given' do
      post api("/projects/#{project.id}/push_rule", user)

      expect(response).to have_gitlab_http_status(400)
    end

    context "user with developer_access" do
      it "does not add push rule to project" do
        post api("/projects/#{project.id}/push_rule", user3), params: rules_params

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe "POST /projects/:id/push_rule" do
    before do
      create(:push_rule, project: project)
    end

    context "with existing push rule" do
      it "does not add push rule to project" do
        post api("/projects/#{project.id}/push_rule", user), params: { deny_delete_tag: true }

        expect(response).to have_gitlab_http_status(422)
      end
    end
  end

  describe "PUT /projects/:id/push_rule" do
    before do
      create(:push_rule, project: project,
             deny_delete_tag: true, commit_message_regex: 'Mended')
      put api("/projects/#{project.id}/push_rule", user), params: new_settings
    end

    context "setting deny_delete_tag and commit_message_regex" do
      let(:new_settings) do
        { deny_delete_tag: false, commit_message_regex: 'Fixes \d+\..*' }
      end

      it "is successful" do
        expect(response).to have_gitlab_http_status(200)
      end

      it 'includes the expected settings' do
        subset = new_settings.transform_keys(&:to_s)
        expect(json_response).to include(subset)
      end
    end

    context "setting commit_committer_check" do
      let(:new_settings) { { commit_committer_check: true } }

      it "is successful" do
        expect(response).to have_gitlab_http_status(200)
      end

      it "sets the commit_committer_check" do
        expect(json_response).to include('commit_committer_check' => true)
      end

      context 'the commit_committer_check feature is not enabled' do
        let(:ccc_enabled) { false }

        it "is an error to provide this parameter" do
          expect(response).to have_gitlab_http_status(403)
        end
      end
    end

    context "setting reject_unsigned_commits" do
      let(:new_settings) { { reject_unsigned_commits: true } }

      it "is successful" do
        expect(response).to have_gitlab_http_status(200)
      end

      it "sets the reject_unsigned_commits" do
        expect(json_response).to include('reject_unsigned_commits' => true)
      end

      context 'the reject_unsigned_commits feature is not enabled' do
        let(:ruc_enabled) { false }

        it "is an error to provide the this parameter" do
          expect(response).to have_gitlab_http_status(403)
        end
      end
    end

    context "not providing parameters" do
      let(:new_settings) { {} }

      it "is an error" do
        expect(response).to have_gitlab_http_status(400)
      end
    end
  end

  describe "PUT /projects/:id/push_rule" do
    it "gets error on non existing project push rule" do
      put api("/projects/#{project.id}/push_rule", user),
        params: { deny_delete_tag: false, commit_message_regex: 'Fixes \d+\..*' }

      expect(response).to have_gitlab_http_status(404)
    end

    it "does not update push rule for unauthorized user" do
      post api("/projects/#{project.id}/push_rule", user3), params: { deny_delete_tag: true }

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe "DELETE /projects/:id/push_rule" do
    before do
      create(:push_rule, project: project)
    end

    context "maintainer" do
      it "deletes push rule from project" do
        delete api("/projects/#{project.id}/push_rule", user)

        expect(response).to have_gitlab_http_status(204)
      end
    end

    context "user with developer_access" do
      it "returns a 403 error" do
        delete api("/projects/#{project.id}/push_rule", user3)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe "DELETE /projects/:id/push_rule" do
    context "for non existing push rule" do
      it "deletes push rule from project" do
        delete api("/projects/#{project.id}/push_rule", user)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response).to be_an Hash
        expect(json_response['message']).to eq('404 Push Rule Not Found')
      end

      it "returns a 403 error if not authorized" do
        delete api("/projects/#{project.id}/push_rule", user3)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end
end
