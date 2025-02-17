# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module Services
            class Jenkins < QA::Page::Base
              view 'app/views/shared/_service_settings.html.haml' do
                element :active_checkbox
              end

              view 'app/views/shared/_field.html.haml' do
                element :jenkins_url_field, 'data: { qa_selector: "#{name.downcase.gsub' # rubocop:disable QA/ElementWithPattern
                element :project_name_field, 'data: { qa_selector: "#{name.downcase.gsub' # rubocop:disable QA/ElementWithPattern
                element :username_field, 'data: { qa_selector: "#{name.downcase.gsub' # rubocop:disable QA/ElementWithPattern
                element :password_field, 'data: { qa_selector: "#{name.downcase.gsub' # rubocop:disable QA/ElementWithPattern
              end

              view 'app/helpers/services_helper.rb' do
                element :save_changes_button
              end

              def setup_service_with(jenkins_url:, project_name:)
                click_active_checkbox
                set_jenkins_url(jenkins_url)
                set_project_name(project_name)
                set_username('admin')
                set_password('password')
                click_save_changes_button
              end

              private

              def click_active_checkbox
                click_element :active_checkbox
              end

              def set_jenkins_url(jenkins_url)
                fill_element(:jenkins_url_field, jenkins_url)
              end

              def set_project_name(project_name)
                fill_element(:project_name_field, project_name)
              end

              def set_username(username)
                fill_element(:username_field, username)
              end

              def set_password(password)
                fill_element(:password_field, password)
              end

              def click_save_changes_button
                click_element :save_changes_button
              end
            end
          end
        end
      end
    end
  end
end
