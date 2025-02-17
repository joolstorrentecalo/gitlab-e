import createState from 'ee/security_dashboard/store/modules/project_selector/state';
import mutations from 'ee/security_dashboard/store/modules/vulnerable_projects/mutations';
import * as types from 'ee/security_dashboard/store/modules/vulnerable_projects/mutation_types';

describe('projectsSelector mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();

    state.isLoading = false;
    state.hasError = false;
  });

  describe('SET_LOADING', () => {
    it('sets state.isLoading to be "true"', () => {
      expect(state.hasError).toBe(false);

      mutations[types.SET_LOADING](state, true);

      expect(state.isLoading).toBe(true);
    });
  });

  describe('SET_PROJECTS', () => {
    it('sets state.projects to the given payload', () => {
      const payload = [];

      mutations[types.SET_PROJECTS](state, payload);

      expect(state.projects).toBe(payload);
    });
  });

  describe('SET_HAS_ERROR', () => {
    it('sets state.projects to be "true"', () => {
      expect(state.hasError).toBe(false);

      mutations[types.SET_HAS_ERROR](state, true);

      expect(state.hasError).toBe(true);
    });
  });
});
