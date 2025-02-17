# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectPackages do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let!(:package1) { create(:npm_package, project: project) }
  let(:package_url) { "/projects/#{project.id}/packages/#{package1.id}" }
  let!(:package2) { create(:npm_package, project: project) }
  let!(:another_package) { create(:npm_package) }
  let(:no_package_url) { "/projects/#{project.id}/packages/0" }
  let(:wrong_package_url) { "/projects/#{project.id}/packages/#{another_package.id}" }

  describe 'GET /projects/:id/packages' do
    let(:url) { "/projects/#{project.id}/packages" }
    let(:package_schema) { 'public_api/v4/packages/packages' }

    subject { get api(url) }

    context 'packages feature enabled' do
      before do
        stub_licensed_features(packages: true)
      end

      context 'project is public' do
        it_behaves_like 'returns packages', :project, :no_type
      end

      context 'project is private' do
        let(:project) { create(:project, :private) }

        context 'for unauthenticated user' do
          it_behaves_like 'rejects packages access', :project, :no_type, :not_found
        end

        context 'for authenticated user' do
          subject { get api(url, user) }

          it_behaves_like 'returns packages', :project, :maintainer
          it_behaves_like 'returns packages', :project, :developer
          it_behaves_like 'returns packages', :project, :reporter
          it_behaves_like 'rejects packages access', :project, :no_type, :not_found
          it_behaves_like 'rejects packages access', :project, :guest, :forbidden

          context 'user is a maintainer' do
            before do
              project.add_maintainer(user)
            end

            it 'returns the destroy url' do
              subject

              expect(json_response.first['_links']).to include('delete_api_path')
            end
          end
        end
      end

      context 'with pagination params' do
        let!(:package3) { create(:maven_package, project: project) }
        let!(:package4) { create(:maven_package, project: project) }

        context 'with pagination params' do
          let!(:package3) { create(:npm_package, project: project) }
          let!(:package4) { create(:npm_package, project: project) }

          it_behaves_like 'returns paginated packages'
        end
      end
    end

    context 'packages feature disabled' do
      before do
        stub_licensed_features(packages: false)
      end

      it 'returns 403' do
        get api(url, user)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe 'GET /projects/:id/packages/:package_id' do
    subject { get api(package_url, user) }

    shared_examples 'no destroy url' do
      it 'returns no destroy url' do
        subject

        expect(json_response['_links']).not_to include('delete_api_path')
      end
    end

    shared_examples 'destroy url' do
      it 'returns destroy url' do
        subject

        expect(json_response['_links']['delete_api_path']).to be_present
      end
    end

    context 'packages feature enabled' do
      before do
        stub_licensed_features(packages: true)
      end

      context 'project is public' do
        it 'returns 200 and the package information' do
          subject

          expect(response).to have_gitlab_http_status(200)
          expect(response).to match_response_schema('public_api/v4/packages/package', dir: 'ee')
        end

        it 'returns 404 when the package does not exist' do
          get api(no_package_url, user)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 404 for the package from a different project' do
          get api(wrong_package_url, user)

          expect(response).to have_gitlab_http_status(404)
        end

        it_behaves_like 'no destroy url'
      end

      context 'project is private' do
        let(:project) { create(:project, :private) }

        it 'returns 404 for non authenticated user' do
          get api(package_url)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 404 for a user without access to the project' do
          subject

          expect(response).to have_gitlab_http_status(404)
        end

        context 'user is a developer' do
          before do
            project.add_developer(user)
          end

          it 'returns 200 and the package information' do
            subject

            expect(response).to have_gitlab_http_status(200)
            expect(response).to match_response_schema('public_api/v4/packages/package', dir: 'ee')
          end

          it_behaves_like 'no destroy url'
        end

        context 'user is a maintainer' do
          before do
            project.add_maintainer(user)
          end

          it_behaves_like 'destroy url'
        end

        context 'with build info' do
          let!(:package1) { create(:npm_package, :with_build, project: project) }

          it 'returns the build info' do
            project.add_developer(user)

            get api(package_url, user)

            expect(response).to have_gitlab_http_status(200)
            expect(response).to match_response_schema('public_api/v4/packages/package_with_build', dir: 'ee')
          end
        end
      end
    end

    context 'packages feature disabled' do
      before do
        stub_licensed_features(packages: false)
      end

      it 'returns 403' do
        subject

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe 'DELETE /projects/:id/packages/:package_id' do
    context 'packages feature enabled' do
      before do
        stub_licensed_features(packages: true)
      end

      context 'project is public' do
        it 'returns 403 for non authenticated user' do
          delete api(package_url)

          expect(response).to have_gitlab_http_status(403)
        end

        it 'returns 403 for a user without access to the project' do
          delete api(package_url, user)

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'project is private' do
        let(:project) { create(:project, :private) }

        it 'returns 404 for non authenticated user' do
          delete api(package_url)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 404 for a user without access to the project' do
          delete api(package_url, user)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 404 when the package does not exist' do
          project.add_maintainer(user)

          delete api(no_package_url, user)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 404 for the package from a different project' do
          project.add_maintainer(user)

          delete api(wrong_package_url, user)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 403 for a user without enough permissions' do
          project.add_developer(user)

          delete api(package_url, user)

          expect(response).to have_gitlab_http_status(403)
        end

        it 'returns 204' do
          project.add_maintainer(user)

          delete api(package_url, user)

          expect(response).to have_gitlab_http_status(204)
        end
      end
    end

    context 'packages feature disabled' do
      before do
        stub_licensed_features(packages: false)
      end

      it 'returns 403' do
        delete api(package_url, user)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end
end
