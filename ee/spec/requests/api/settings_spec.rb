# frozen_string_literal: true

require 'spec_helper'

describe API::Settings, 'EE Settings' do
  include StubENV

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:project) { create(:project) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe "PUT /application/settings" do
    it 'sets EE specific settings' do
      stub_licensed_features(custom_file_templates: true)

      put api("/application/settings", admin),
        params: {
          help_text: 'Help text',
          file_template_project_id: project.id
        }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['help_text']).to eq('Help text')
      expect(json_response['file_template_project_id']).to eq(project.id)
    end

    context 'elasticsearch settings' do
      it 'limits namespaces and projects properly' do
        namespace_ids = create_list(:namespace, 2).map(&:id)
        project_ids = create_list(:project, 2).map(&:id)

        put api('/application/settings', admin),
            params: {
              elasticsearch_limit_indexing: true,
              elasticsearch_project_ids: project_ids.join(','),
              elasticsearch_namespace_ids: namespace_ids.join(',')
            }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['elasticsearch_limit_indexing']).to eq(true)
        expect(json_response['elasticsearch_project_ids']).to eq(project_ids)
        expect(json_response['elasticsearch_namespace_ids']).to eq(namespace_ids)
        expect(ElasticsearchIndexedNamespace.count).to eq(2)
        expect(ElasticsearchIndexedProject.count).to eq(2)
      end

      it 'removes namespaces and projects properly' do
        stub_ee_application_setting(elasticsearch_limit_indexing: true)
        create(:elasticsearch_indexed_namespace).namespace.id
        create(:elasticsearch_indexed_project).project.id

        put api('/application/settings', admin),
            params: {
              elasticsearch_namespace_ids: []
            }.to_json,
            headers: {
              'CONTENT_TYPE' => 'application/json'
            }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['elasticsearch_namespace_ids']).to eq([])
        expect(ElasticsearchIndexedNamespace.count).to eq(0)
        expect(ElasticsearchIndexedProject.count).to eq(1)
      end
    end
  end

  shared_examples 'settings for licensed features' do
    let(:attribute_names) { settings.keys.map(&:to_s) }

    before do
      # Make sure the settings exist before the specs
      get api("/application/settings", admin)
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(feature => false)
      end

      it 'hides the attributes in the API' do
        get api("/application/settings", admin)

        expect(response).to have_gitlab_http_status(200)
        attribute_names.each do |attribute|
          expect(json_response.keys).not_to include(attribute)
        end
      end

      it 'does not update application settings' do
        expect { put api("/application/settings", admin), params: settings }
          .not_to change { ApplicationSetting.current.reload.attributes.slice(*attribute_names) }
      end
    end

    context 'when the feature is available' do
      before do
        stub_licensed_features(feature => true)
      end

      it 'includes the attributes in the API' do
        get api("/application/settings", admin)

        expect(response).to have_gitlab_http_status(200)
        attribute_names.each do |attribute|
          expect(json_response.keys).to include(attribute)
        end
      end

      it 'allows updating the settings' do
        put api("/application/settings", admin), params: settings
        expect(response).to have_gitlab_http_status(200)

        settings.each do |attribute, value|
          expect(ApplicationSetting.current.public_send(attribute)).to eq(value)
        end
      end
    end
  end

  context 'mirroring settings' do
    let(:settings) { { mirror_max_capacity: 15 } }
    let(:feature) { :repository_mirrors }

    it_behaves_like 'settings for licensed features'
  end

  context 'custom email footer' do
    let(:settings) { { email_additional_text: 'this is a scary legal footer' } }
    let(:feature) { :email_additional_text }

    it_behaves_like 'settings for licensed features'
  end

  context 'default project deletion protection' do
    let(:settings) { { default_project_deletion_protection: true } }
    let(:feature) { :default_project_deletion_protection }

    it_behaves_like 'settings for licensed features'
  end

  context 'deletion adjourned period' do
    let(:settings) { { deletion_adjourned_period: 5 } }
    let(:feature) { :marking_project_for_deletion }

    it_behaves_like 'settings for licensed features'
  end

  context 'custom file template project' do
    let(:settings) { { file_template_project_id: project.id } }
    let(:feature) { :custom_file_templates }

    it_behaves_like 'settings for licensed features'
  end

  context 'updating name disabled for users' do
    let(:settings) { { updating_name_disabled_for_users: true } }
    let(:feature) { :disable_name_update_for_users }

    it_behaves_like 'settings for licensed features'
  end
end
