# frozen_string_literal: true

module QA
  context 'Geo', :orchestrated, :geo do
    describe 'GitLab Geo attachment replication' do
      let(:file_to_attach) { File.absolute_path(File.join('spec', 'fixtures', 'banana_sample.gif')) }

      it 'user uploads attachment to the primary node' do
        QA::Flow::Login.while_signed_in(address: :geo_primary) do
          @project = Resource::Project.fabricate! do |project|
            project.name = 'project-for-issues'
            project.description = 'project for adding issues'
          end

          @issue = Resource::Issue.fabricate! do |issue|
            issue.title = 'My geo issue'
            issue.project = @project
          end

          @issue.visit!

          Page::Project::Issue::Show.perform do |show|
            show.comment('See attached banana for scale', attachment: file_to_attach)
          end
        end

        QA::Flow::Login.while_signed_in(address: :geo_secondary) do
          EE::Page::Main::Banner.perform do |banner|
            expect(banner).to have_secondary_read_only_banner
          end

          expect(page).to have_content 'You are on a secondary, read-only Geo node'

          Page::Main::Menu.perform do |menu|
            menu.go_to_projects
          end

          Page::Dashboard::Projects.perform do |dashboard|
            dashboard.wait_for_project_replication(@project.name)

            dashboard.go_to_project(@project.name)
          end

          Page::Project::Menu.act { click_issues }

          Page::Project::Issue::Index.perform do |index|
            index.wait_for_issue_replication(@issue)
          end

          image_url = find('a[href$="banana_sample.gif"]')[:href]

          Page::Project::Issue::Show.perform do |show|
            # Wait for attachment replication
            found = show.wait_until(reload: false) do
              show.asset_exists?(image_url)
            end

            expect(found).to be_truthy
          end
        end
      end
    end
  end
end
