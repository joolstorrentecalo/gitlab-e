# frozen_string_literal: true

require 'spec_helper'

describe SearchService do
  describe '#search_objects' do
    context 'redacting search results' do
      let(:user) { create(:user) }

      # Resources the user has access to
      let(:project) { create(:project) }
      let(:issue_in_project) { create(:issue, project: project) }
      let(:note_on_issue_in_project) { create(:note, project: project, noteable: issue_in_project) }
      let(:merge_request_in_project) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
      let(:milestone_in_project) { create(:milestone, project: project) }

      # Resources the user does not have access to
      let(:unauthorized_project) { create(:project, :repository, :wiki_repo) }
      let(:issue1_in_unauthorized_project) { create(:issue, project: unauthorized_project) }
      let(:issue2_in_unauthorized_project) { create(:issue, project: unauthorized_project) }
      let(:note_on_unauthorized_issue) { create(:note, project: unauthorized_project, noteable: issue1_in_unauthorized_project) }
      let(:merge_request_in_unauthorized_project) { create(:merge_request_with_diffs, target_project: unauthorized_project, source_project: unauthorized_project) }
      let(:milestone_in_unauthorized_project) { create(:milestone, project: unauthorized_project) }
      let(:wiki_page) { WikiPages::CreateService.new(unauthorized_project, user, { title: "foo", content: "wiki_blobs" }).execute }
      let(:commit) { unauthorized_project.repository.commit(SeedRepo::FirstCommit::ID) }

      let(:search_service) { described_class.new(user, search: 'some-search-string', page: 1) }
      let(:mock_global_service) { instance_double(Search::GlobalService, scope: 'some-scope') }
      let(:mock_results) { instance_double(Gitlab::Elastic::SearchResults) }

      subject { search_service.search_objects }

      before do
        project.add_maintainer(user)
        allow(Search::GlobalService).to receive(:new).with(user, anything).and_return(mock_global_service)
        allow(mock_global_service).to receive(:execute).and_return(mock_results)
      end

      it 'redacts projects the user does not have access to' do
        allow(mock_results).to receive(:objects)
          .and_return(
            Kaminari.paginate_array(
              [
                project,
                unauthorized_project
              ],
              total_count: 2,
              limit: 2,
              offset: 0
            )
          )

        expect(search_service.send(:logger))
          .to receive(:error)
          .with(hash_including(
                  message: "redacted_search_results",
                  current_user_id: user.id,
                  query: 'some-search-string',
                  filtered: array_including([
                    { class_name: "Project", id: unauthorized_project.id, ability: :read_project }
                  ])))

        expect(subject).to be_kind_of(Kaminari::PaginatableArray)
        expect(subject).to contain_exactly(project)
      end

      it 'redacts issues the user does not have access to' do
        allow(mock_results).to receive(:objects)
          .and_return(
            Kaminari.paginate_array(
              [
                issue_in_project,
                issue1_in_unauthorized_project,
                issue2_in_unauthorized_project
              ],
              total_count: 3,
              limit: 3,
              offset: 0
            )
          )

        expect(search_service.send(:logger))
          .to receive(:error)
          .with(hash_including(
                  message: "redacted_search_results",
                  current_user_id: user.id,
                  query: 'some-search-string',
                  filtered: array_including([
                    { class_name: "Issue", id: issue1_in_unauthorized_project.id, ability: :read_issue },
                    { class_name: "Issue", id: issue2_in_unauthorized_project.id, ability: :read_issue }
                  ])))

        expect(subject).to be_kind_of(Kaminari::PaginatableArray)
        expect(subject).to contain_exactly(issue_in_project)
      end

      it 'redacts merge requests the user does not have access to' do
        allow(mock_results).to receive(:objects)
          .and_return(
            Kaminari.paginate_array(
              [
                merge_request_in_project,
                merge_request_in_unauthorized_project
              ],
              total_count: 2,
              limit: 2,
              offset: 0
            )
          )

        expect(subject).to be_kind_of(Kaminari::PaginatableArray)
        expect(subject).to contain_exactly(merge_request_in_project)
      end

      it 'redacts milestones the user does not have access to' do
        allow(mock_results).to receive(:objects)
          .and_return(
            Kaminari.paginate_array(
              [
                milestone_in_project,
                milestone_in_unauthorized_project
              ],
              total_count: 2,
              limit: 2,
              offset: 0
            )
          )

        expect(subject).to be_kind_of(Kaminari::PaginatableArray)
        expect(subject).to contain_exactly(milestone_in_project)
      end

      it 'redacts notes the user does not have access to' do
        allow(mock_results).to receive(:objects)
          .and_return(
            Kaminari.paginate_array(
              [
                note_on_issue_in_project,
                note_on_unauthorized_issue
              ],
              total_count: 2,
              limit: 2,
              offset: 0
            )
          )

        expect(subject).to be_kind_of(Kaminari::PaginatableArray)
        expect(subject).to contain_exactly(note_on_issue_in_project)
      end

      it 'redacts commits the user does not have access to' do
        allow(mock_results).to receive(:objects)
          .and_return(
            Kaminari.paginate_array(
              [
                commit
              ],
              total_count: 1,
              limit: 1,
              offset: 0
            )
          )

        expect(subject).to be_kind_of(Kaminari::PaginatableArray)
        expect(subject).to be_empty
      end

      it 'redacts blobs the user does not have access to' do
        blob = unauthorized_project.repository.blob_at(SeedRepo::FirstCommit::ID, 'README.md')
        response = Elasticsearch::Model::Response::Response.new Blob, double(:search)

        allow(response).to receive_messages(
          results: [blob],
          total_count: 1,
          limit_value: 10,
          offset_value: 0
        )
        allow(mock_results).to receive(:objects).and_return(response)

        expect(subject).to be_kind_of(Kaminari::PaginatableArray)
        expect(subject).to be_empty
      end

      it 'redacts wikis the user does not have access to' do
        wiki_page = create(:wiki_page, wiki: unauthorized_project.wiki)
        response = Elasticsearch::Model::Response::Response.new WikiPage, double(:search)

        allow(response).to receive_messages(
          results: [wiki_page],
          total_count: 1,
          limit_value: 10,
          offset_value: 0
        )
        allow(mock_results).to receive(:objects).and_return(response)

        expect(subject).to be_kind_of(Kaminari::PaginatableArray)
        expect(subject).to be_empty
      end
    end
  end
end
