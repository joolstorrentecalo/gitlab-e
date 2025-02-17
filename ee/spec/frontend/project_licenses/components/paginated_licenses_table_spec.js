import { shallowMount } from '@vue/test-utils';
import createStore from 'ee/project_licenses/store';
import LicensesTable from 'ee/project_licenses/components/licenses_table.vue';
import { toLicenseObject } from 'ee/project_licenses/utils/mappers';
import { LICENSE_LIST } from 'ee/project_licenses/store/constants';
import PaginatedLicensesTable from 'ee/project_licenses/components/paginated_licenses_table.vue';
import Pagination from '~/vue_shared/components/pagination_links.vue';
import mockLicensesResponse from '../store/modules/list/data/mock_licenses';

jest.mock('underscore', () => ({
  uniqueId: () => 'fakeUniqueId',
}));

describe('PaginatedLicensesTable component', () => {
  const namespace = LICENSE_LIST;

  let store;
  let wrapper;

  const factory = () => {
    store = createStore();

    wrapper = shallowMount(PaginatedLicensesTable, {
      store,
    });
  };

  const expectComponentWithProps = (Component, props = {}) => {
    const componentWrapper = wrapper.find(Component);
    expect(componentWrapper.isVisible()).toBe(true);
    expect(componentWrapper.props()).toEqual(expect.objectContaining(props));
  };

  beforeEach(() => {
    factory();

    store.dispatch(`${namespace}/receiveLicensesSuccess`, {
      data: mockLicensesResponse,
      headers: { 'X-Total': mockLicensesResponse.licenses.length },
    });

    jest.spyOn(store, 'dispatch').mockImplementation();

    return wrapper.vm.$nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('passes the correct props to the licenses table', () => {
    expectComponentWithProps(LicensesTable, {
      licenses: mockLicensesResponse.licenses.map(toLicenseObject),
      isLoading: store.state[namespace].isLoading,
    });
  });

  it('passes the correct props to the pagination', () => {
    expectComponentWithProps(Pagination, {
      change: wrapper.vm.fetchPage,
      pageInfo: store.state[namespace].pageInfo,
    });
  });

  it('has a fetchPage method which dispatches the correct action', () => {
    const page = 2;
    wrapper.vm.fetchPage(page);
    expect(store.dispatch).toHaveBeenCalledTimes(1);
    expect(store.dispatch).toHaveBeenCalledWith(`${namespace}/fetchLicenses`, { page });
  });

  describe.each`
    context                             | isLoading | errorLoading | isListEmpty | initialized
    ${'the list is loading'}            | ${true}   | ${false}     | ${false}    | ${false}
    ${'the list is empty (initalized)'} | ${false}  | ${false}     | ${true}     | ${true}
    ${'the list is empty'}              | ${false}  | ${false}     | ${true}     | ${false}
    ${'there was an error loading'}     | ${false}  | ${true}      | ${false}    | ${false}
  `('given $context', ({ isLoading, errorLoading, isListEmpty, initialized }) => {
    let moduleState;

    beforeEach(() => {
      moduleState = Object.assign(store.state[namespace], {
        isLoading,
        errorLoading,
        initialized,
      });

      if (isListEmpty) {
        moduleState.licenses = [];
        moduleState.pageInfo.total = 0;
      }

      return wrapper.vm.$nextTick();
    });

    // See https://github.com/jest-community/eslint-plugin-jest/issues/229 for
    // a similar reason for disabling the rule on the next line
    // eslint-disable-next-line jest/no-identical-title
    it('passes the correct props to the licenses table', () => {
      expectComponentWithProps(LicensesTable, {
        licenses: moduleState.licenses,
        isLoading,
      });
    });

    it('does not render pagination', () => {
      expect(wrapper.find(Pagination).exists()).toBe(false);
    });
  });
});
