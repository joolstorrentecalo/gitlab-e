# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'Configure issue board by label' do
      let(:label_board_list) do
        EE::Resource::Board::BoardList::Project::LabelBoardList.fabricate_via_api!
      end

      let(:doing) { 'Doing' }
      let(:ready_for_dev) { 'Ready for development' }

      let(:issue_1) { 'Issue 1' }
      let(:issue_2) { 'Issue 2' }

      before do
        Flow::Login.sign_in

        fabricate_issue_with_label(label_board_list.project, issue_1, doing)
        fabricate_issue_with_label(label_board_list.project, issue_2, ready_for_dev)

        label_board_list.project.visit!
        Page::Project::Menu.perform(&:go_to_boards)
      end

      it 'shows only issues that match the configured label' do
        EE::Page::Component::IssueBoard::Show.perform do |show|
          show.configure_by_label(doing)

          expect(show).not_to have_content(issue_2)
          expect(show.boards_list_cards_area_with_index(1)).to have_content(issue_1)
        end
      end

      def fabricate_issue_with_label(project, title, label)
        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
          issue.title = title
          issue.labels = [label]
        end
      end
    end
  end
end
