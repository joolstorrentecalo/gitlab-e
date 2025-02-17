# frozen_string_literal: true

module QA
  # This test was quarantined because relative URL isn't supported
  # See https://gitlab.com/gitlab-org/gitlab/issues/13833
  # It's now skipped because another bug breaks the projects list and
  # causes subsequent tests to fail
  # See https://gitlab.com/gitlab-org/gitlab/issues/197130
  # BUG_IN_CODE
  context 'Create', :skip do
    describe 'Web IDE web terminal', :docker do
      before do
        project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'web-terminal-project'
        end

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab/.gitlab-webide.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab/.gitlab-webide.yml',
                content: <<~YAML
                  terminal:
                    tags: ["web-ide"]
                    script: sleep 60
                YAML
              }
            ]
          )
        end

        @runner = Resource::Runner.fabricate_via_api! do |runner|
          runner.project = project
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = %w[web-ide]
          runner.image = 'gitlab/gitlab-runner:latest'
          runner.config = <<~END
            concurrent = 1

            [session_server]
              listen_address = "0.0.0.0:8093"
              advertise_address = "localhost:8093"
              session_timeout = 120
          END
        end

        Flow::Login.sign_in

        project.visit!
      end

      after do
        # Remove the runner even if the test fails
        Service::DockerRun::GitlabRunner.new(@runner.name).remove! if @runner
      end

      it 'user starts the web terminal' do
        Page::Project::Show.perform(&:open_web_ide!)

        # Start the web terminal and check that there were no errors
        # The terminal screen is a canvas element, so we can't read its content,
        # so we infer that it's working if:
        #  a) The terminal JS package has loaded, and
        #  b) It's not stuck in a "Loading/Starting" state, and
        #  c) There's no alert stating there was a problem
        #
        # The terminal itself is a third-party package so we assume it is
        # adequately tested elsewhere.
        #
        # There are also FE specs
        # * ee/spec/javascripts/ide/components/terminal/terminal_spec.js
        # * ee/spec/frontend/ide/components/terminal/terminal_controls_spec.js
        Page::Project::WebIDE::Edit.perform do |edit|
          edit.start_web_terminal

          expect(edit).to have_no_alert
          expect(edit).to have_finished_loading
          expect(edit).to have_terminal_screen
        end
      end
    end
  end
end
