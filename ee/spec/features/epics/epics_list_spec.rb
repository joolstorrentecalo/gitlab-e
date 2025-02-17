# frozen_string_literal: true

require 'spec_helper'

describe 'epics list', :js do
  let(:group) { create(:group, :public) }
  let(:user) { create(:user) }

  before do
    stub_licensed_features(epics: true)

    sign_in(user)
  end

  context 'when epics exist for the group' do
    let!(:epic1) { create(:epic, group: group, end_date: 10.days.ago) }
    let!(:epic2) { create(:epic, group: group, start_date: 2.days.ago) }
    let!(:epic3) { create(:epic, group: group, start_date: 10.days.ago, end_date: 5.days.ago) }

    before do
      visit group_epics_path(group)
    end

    it 'shows epics tabs for each status type' do
      page.within('.epics-state-filters') do
        expect(page).to have_selector('li > a#state-opened')
        expect(find('li > a#state-opened')[:title]).to eq('Filter by epics that are currently opened.')

        expect(page).to have_selector('li > a#state-closed')
        expect(find('li > a#state-closed')[:title]).to eq('Filter by epics that are currently closed.')

        expect(page).to have_selector('li > a#state-all')
        expect(find('li > a#state-all')[:title]).to eq('Show all epics.')
      end
    end

    it 'shows the epics in the navigation sidebar' do
      expect(first('.nav-sidebar  .active a .nav-item-name')).to have_content('Epics')
      expect(first('.nav-sidebar .active a .count')).to have_content('3')
    end

    it 'shows epic updated date and comment count' do
      page.within('.issuable-list') do
        page.within('li:nth-child(1) .issuable-meta') do
          expect(find('.issuable-updated-at')).to have_content('updated just now')
          expect(find('.issuable-comments')).to have_content('0')
        end
      end
    end

    it 'shows epic start and/or end dates when present' do
      page.within('.issuable-list') do
        expect(find("li[data-id='#{epic1.id}'] .issuable-info .issuable-dates")).to have_content("Until #{epic1.end_date.strftime('%b %d, %Y')}")
        expect(find("li[data-id='#{epic2.id}'] .issuable-info .issuable-dates")).to have_content("From #{epic2.start_date.strftime('%b %d, %Y')}")
      end
    end

    it 'renders the filtered search bar correctly' do
      page.within('.content-wrapper .content') do
        expect(page).to have_css('.epics-filters')
      end
    end

    it 'sorts by created_at DESC by default' do
      expect(page).to have_button('Created date')

      page.within('.content-wrapper .content') do
        expect(find('.top-area')).to have_content('All 3')

        page.within('.issuable-list') do
          page.within('li:nth-child(1) .issuable-main-info') do
            expect(page).to have_content(epic3.title)
          end

          page.within('li:nth-child(2) .issuable-main-info') do
            expect(page).to have_content(epic2.title)
          end

          page.within('li:nth-child(3) .issuable-main-info') do
            expect(page).to have_content(epic1.title)
          end
        end
      end
    end

    it 'sorts by the selected value and stores the selection for epic list' do
      page.within('.epics-other-filters') do
        click_button 'Created date'
        sort_options = find('ul.dropdown-menu-sort li').all('a').collect(&:text)

        expect(sort_options[0]).to eq('Created date')
        expect(sort_options[1]).to eq('Last updated')
        expect(sort_options[2]).to eq('Start date')
        expect(sort_options[3]).to eq('Due date')

        click_link 'Last updated'
      end

      expect(page).to have_button('Last updated')

      page.within('.content-wrapper .content') do
        expect(find('.top-area')).to have_content('All 3')

        page.within('.issuable-list') do
          page.within('li:nth-child(1) .issuable-main-info') do
            expect(page).to have_content(epic3.title)
          end

          page.within('li:nth-child(2) .issuable-main-info') do
            expect(page).to have_content(epic2.title)
          end

          page.within('li:nth-child(3) .issuable-main-info') do
            expect(page).to have_content(epic1.title)
          end
        end
      end

      visit group_epics_path(group)

      expect(page).to have_button('Last updated')
    end

    it 'sorts by the selected value and stores the selection for roadmap' do
      visit group_roadmap_path(group)

      page.within('.epics-other-filters') do
        click_button 'Start date'
        sort_options = find('ul.dropdown-menu-sort li').all('a').collect(&:text)

        expect(sort_options[0]).to eq('Start date')
        expect(sort_options[1]).to eq('Due date')

        click_link 'Due date'
      end

      expect(page).to have_button('Due date')

      page.within('.content-wrapper .content') do
        page.within('.epics-list-section') do
          page.within('div.epics-list-item:nth-child(1)') do
            expect(page).to have_content(epic1.title)
          end

          page.within('div.epics-list-item:nth-child(2)') do
            expect(page).to have_content(epic3.title)
          end

          page.within('div.epics-list-item:nth-child(3)') do
            expect(page).to have_content(epic2.title)
          end
        end
      end

      visit group_roadmap_path(group)

      expect(page).to have_button('Due date')
    end

    it 'renders the epic detail correctly after clicking the link' do
      page.within('.content-wrapper .content .issuable-list') do
        click_link(epic1.title)
      end

      wait_for_requests

      expect(page.find('.issuable-details h2.title')).to have_content(epic1.title)
    end
  end

  context 'when closed epics exist for the group' do
    let!(:epic1) { create(:epic, :closed, group: group, end_date: 10.days.ago) }

    before do
      visit group_epics_path(group)
    end

    it 'shows epic status, updated date and comment count' do
      page.within('.epics-state-filters') do
        click_link 'Closed'
      end

      page.within('.issuable-list') do
        page.within('li:nth-child(1) .issuable-meta') do
          expect(find('.issuable-status')).to have_content('CLOSED')
          expect(find('.issuable-updated-at')).to have_content('updated just now')
          expect(find('.issuable-comments')).to have_content('0')
        end
      end
    end
  end

  context 'when no epics exist for the group' do
    before do
      visit group_epics_path(group)
    end

    it 'renders the empty list page' do
      within('#content-body') do
        expect(find('.empty-state h4'))
          .to have_content('Epics let you manage your portfolio of projects more efficiently and with less effort')
      end
    end

    it 'shows epics tabs for each status type' do
      page.within('.epics-state-filters') do
        expect(page).to have_selector('li > a#state-opened')
        expect(page).to have_selector('li > a#state-closed')
        expect(page).to have_selector('li > a#state-all')
      end
    end
  end
end
