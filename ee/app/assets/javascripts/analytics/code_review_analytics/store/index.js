import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

const createStore = () =>
  new Vuex.Store({
    state: state(),
    actions,
    getters,
    mutations,
  });

export default createStore();
