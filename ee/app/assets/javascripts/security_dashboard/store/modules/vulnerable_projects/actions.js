import axios from 'axios';

import { __ } from '~/locale';
import createFlash from '~/flash';

import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

import { SET_LOADING, SET_PROJECTS, SET_HAS_ERROR } from './mutation_types';

export const fetchProjects = ({ dispatch }, endpoint) => {
  dispatch('requestProjects');

  // in the future this will be moved to `ee/api.js`
  // see https://gitlab.com/gitlab-org/gitlab/merge_requests/20892#note_253602076
  return axios
    .get(endpoint)
    .then(({ data }) => data.map(convertObjectPropsToCamelCase))
    .then(data => {
      dispatch('receiveProjectsSuccess', data);
    })
    .catch(() => {
      dispatch('receiveProjectsError');
    });
};

export const requestProjects = ({ commit }) => {
  commit(SET_LOADING, true);
  commit(SET_HAS_ERROR, false);
};

export const receiveProjectsSuccess = ({ commit }, payload) => {
  commit(SET_LOADING, false);
  commit(SET_PROJECTS, payload);
};

export const receiveProjectsError = ({ commit }) => {
  createFlash(__('Unable to fetch vulnerable projects'));

  commit(SET_HAS_ERROR, true);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
// This is no longer needed after gitlab-foss#52179 is merged
export default () => {};
