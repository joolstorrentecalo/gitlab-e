import Api from 'ee/api';
import { backOff } from '~/lib/utils/common_utils';
import httpStatusCodes from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import { s__ } from '~/locale';
import * as types from './mutation_types';

import { getTimeRange } from '../utils';
import { timeWindows } from '../constants';

const requestLogsUntilData = params =>
  backOff((next, stop) => {
    Api.getPodLogs(params)
      .then(res => {
        if (res.status === httpStatusCodes.ACCEPTED) {
          next();
          return;
        }
        stop(res);
      })
      .catch(err => {
        stop(err);
      });
  });

export const setInitData = ({ dispatch, commit }, { projectPath, environmentName, podName }) => {
  commit(types.SET_PROJECT_PATH, projectPath);
  commit(types.SET_PROJECT_ENVIRONMENT, environmentName);
  commit(types.SET_CURRENT_POD_NAME, podName);
  dispatch('fetchLogs');
};

export const showPodLogs = ({ dispatch, commit }, podName) => {
  commit(types.SET_CURRENT_POD_NAME, podName);
  dispatch('fetchLogs');
};

export const setSearch = ({ dispatch, commit }, searchQuery) => {
  commit(types.SET_SEARCH, searchQuery);
  dispatch('fetchLogs');
};

export const setTimeWindow = ({ dispatch, commit }, timeWindowKey) => {
  commit(types.SET_TIME_WINDOW, timeWindowKey);
  dispatch('fetchLogs');
};

export const showEnvironment = ({ dispatch, commit }, environmentName) => {
  commit(types.SET_PROJECT_ENVIRONMENT, environmentName);
  commit(types.SET_CURRENT_POD_NAME, null);
  dispatch('fetchLogs');
};

export const fetchEnvironments = ({ commit }, environmentsPath) => {
  commit(types.REQUEST_ENVIRONMENTS_DATA);

  axios
    .get(environmentsPath)
    .then(({ data }) => {
      commit(types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS, data.environments);
    })
    .catch(() => {
      commit(types.RECEIVE_ENVIRONMENTS_DATA_ERROR);
      flash(s__('Metrics|There was an error fetching the environments data, please try again'));
    });
};

export const fetchLogs = ({ commit, state }) => {
  const params = {
    projectPath: state.projectPath,
    environmentName: state.environments.current,
    podName: state.pods.current,
    search: state.search,
  };

  if (state.timeWindow.current) {
    const { current } = state.timeWindow;
    const { start, end } = getTimeRange(timeWindows[current].seconds);

    params.start = start;
    params.end = end;
  }

  commit(types.REQUEST_PODS_DATA);
  commit(types.REQUEST_LOGS_DATA);

  return requestLogsUntilData(params)
    .then(({ data }) => {
      const { pod_name, pods, logs, enable_advanced_querying } = data;
      commit(types.ENABLE_ADVANCED_QUERYING, enable_advanced_querying);
      commit(types.SET_CURRENT_POD_NAME, pod_name);

      commit(types.RECEIVE_PODS_DATA_SUCCESS, pods);
      commit(types.RECEIVE_LOGS_DATA_SUCCESS, logs);
    })
    .catch(() => {
      commit(types.RECEIVE_PODS_DATA_ERROR);
      commit(types.RECEIVE_LOGS_DATA_ERROR);
      flash(s__('Metrics|There was an error fetching the logs, please try again'));
    });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
