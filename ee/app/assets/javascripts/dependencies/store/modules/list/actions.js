import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import createFlash from '~/flash';
import { FETCH_ERROR_MESSAGE } from './constants';
import { isValidResponse } from './utils';
import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

export const setDependenciesEndpoint = ({ commit }, endpoint) =>
  commit(types.SET_DEPENDENCIES_ENDPOINT, endpoint);

export const requestDependencies = ({ commit }) => commit(types.REQUEST_DEPENDENCIES);

export const receiveDependenciesSuccess = ({ commit }, { headers, data }) => {
  const normalizedHeaders = normalizeHeaders(headers);
  const pageInfo = parseIntPagination(normalizedHeaders);
  const { dependencies, report: reportInfo } = data;

  commit(types.RECEIVE_DEPENDENCIES_SUCCESS, { dependencies, reportInfo, pageInfo });
};

export const receiveDependenciesError = ({ commit }, error) =>
  commit(types.RECEIVE_DEPENDENCIES_ERROR, error);

export const fetchDependencies = ({ state, dispatch }, params = {}) => {
  if (!state.endpoint) {
    return;
  }

  dispatch('requestDependencies');

  axios
    .get(state.endpoint, {
      params: {
        sort_by: state.sortField,
        sort: state.sortOrder,
        page: state.pageInfo.page || 1,
        ...params,
      },
    })
    .then(response => {
      if (isValidResponse(response)) {
        dispatch('receiveDependenciesSuccess', response);
      } else {
        throw new Error(__('Invalid server response'));
      }
    })
    .catch(error => {
      dispatch('receiveDependenciesError', error);
      createFlash(FETCH_ERROR_MESSAGE);
    });
};

export const setSortField = ({ commit, dispatch }, id) => {
  commit(types.SET_SORT_FIELD, id);
  dispatch('fetchDependencies', { page: 1 });
};

export const toggleSortOrder = ({ commit, dispatch }) => {
  commit(types.TOGGLE_SORT_ORDER);
  dispatch('fetchDependencies', { page: 1 });
};
