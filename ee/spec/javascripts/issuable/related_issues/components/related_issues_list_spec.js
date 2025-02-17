import { mount } from '@vue/test-utils';
import RelatedIssuesList from 'ee/related_issues/components/related_issues_list.vue';
import {
  issuable1,
  issuable2,
  issuable3,
  issuable4,
  issuable5,
} from 'spec/vue_shared/components/issue/related_issuable_mock_data';
import { PathIdSeparator } from 'ee/related_issues/constants';

describe('RelatedIssuesList', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with defaults', () => {
    beforeEach(() => {
      wrapper = mount(RelatedIssuesList, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          issuableType: 'issue',
        },
      });
    });

    it('should not show loading icon', () => {
      expect(wrapper.vm.$refs.loadingIcon).toBeUndefined();
    });
  });

  describe('with isFetching=true', () => {
    beforeEach(() => {
      wrapper = mount(RelatedIssuesList, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          isFetching: true,
          issuableType: 'issue',
        },
      });
    });

    it('should show loading icon', () => {
      expect(wrapper.vm.$refs.loadingIcon).toBeDefined();
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      wrapper = mount(RelatedIssuesList, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          relatedIssues: [issuable1, issuable2, issuable3, issuable4, issuable5],
          issuableType: 'issue',
        },
      });
    });

    it('updates the order correctly when an item is moved to the top', () => {
      const beforeAfterIds = wrapper.vm.getBeforeAfterId(
        wrapper.vm.$el.querySelector('ul li:first-child'),
      );

      expect(beforeAfterIds.beforeId).toBeNull();
      expect(beforeAfterIds.afterId).toBe(2);
    });

    it('updates the order correctly when an item is moved to the bottom', () => {
      const beforeAfterIds = wrapper.vm.getBeforeAfterId(
        wrapper.vm.$el.querySelector('ul li:last-child'),
      );

      expect(beforeAfterIds.beforeId).toBe(4);
      expect(beforeAfterIds.afterId).toBeNull();
    });

    it('updates the order correctly when an item is swapped with adjacent item', () => {
      const beforeAfterIds = wrapper.vm.getBeforeAfterId(
        wrapper.vm.$el.querySelector('ul li:nth-child(3)'),
      );

      expect(beforeAfterIds.beforeId).toBe(2);
      expect(beforeAfterIds.afterId).toBe(4);
    });

    it('updates the order correctly when an item is moved somewhere in the middle', () => {
      const beforeAfterIds = wrapper.vm.getBeforeAfterId(
        wrapper.vm.$el.querySelector('ul li:nth-child(4)'),
      );

      expect(beforeAfterIds.beforeId).toBe(3);
      expect(beforeAfterIds.afterId).toBe(5);
    });
  });

  describe('issuableOrderingId returns correct issuable order id when', () => {
    it('issuableType is epic', () => {
      wrapper = mount(RelatedIssuesList, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          issuableType: 'issue',
        },
      });

      expect(wrapper.vm.issuableOrderingId(issuable1)).toBe(issuable1.epicIssueId);
    });

    it('issuableType is issue', () => {
      wrapper = mount(RelatedIssuesList, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          issuableType: 'epic',
        },
      });

      expect(wrapper.vm.issuableOrderingId(issuable1)).toBe(issuable1.id);
    });
  });

  describe('renders correct ordering id when', () => {
    let relatedIssues;

    beforeAll(() => {
      relatedIssues = [issuable1, issuable2, issuable3, issuable4, issuable5];
    });

    it('issuableType is epic', () => {
      wrapper = mount(RelatedIssuesList, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          issuableType: 'epic',
          relatedIssues,
        },
      });

      const listItems = wrapper.vm.$el.querySelectorAll('.list-item');

      Array.from(listItems).forEach((item, index) => {
        expect(Number(item.dataset.orderingId)).toBe(relatedIssues[index].id);
      });
    });

    it('issuableType is issue', () => {
      wrapper = mount(RelatedIssuesList, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          issuableType: 'issue',
          relatedIssues,
        },
      });

      const listItems = wrapper.vm.$el.querySelectorAll('.list-item');

      Array.from(listItems).forEach((item, index) => {
        expect(Number(item.dataset.orderingId)).toBe(relatedIssues[index].epicIssueId);
      });
    });
  });

  describe('with :issue_link_types feature flag on', () => {
    it('shows a heading', () => {
      const heading = 'Related';

      wrapper = mount(RelatedIssuesList, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          issuableType: 'issue',
          heading,
        },
        provide: {
          glFeatures: {
            issueLinkTypes: true,
          },
        },
      });

      expect(wrapper.find('h4').text()).toContain(heading);
    });
  });
});
