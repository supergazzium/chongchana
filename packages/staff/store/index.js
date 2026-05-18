const WORKING_BRANCH_STORAGE_KEY = 'staff_working_branch_v1';
const STALE_AFTER_MS = 4 * 60 * 60 * 1000; // 4 hours

function loadFromStorage() {
  if (typeof window === 'undefined' || !window.localStorage) return null;
  try {
    const raw = window.localStorage.getItem(WORKING_BRANCH_STORAGE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    if (!parsed || !parsed.branch || !parsed.selectedAt) return null;
    return parsed;
  } catch (e) {
    return null;
  }
}

function saveToStorage(payload) {
  if (typeof window === 'undefined' || !window.localStorage) return;
  try {
    window.localStorage.setItem(WORKING_BRANCH_STORAGE_KEY, JSON.stringify(payload));
  } catch (e) {}
}

function clearStorage() {
  if (typeof window === 'undefined' || !window.localStorage) return;
  try {
    window.localStorage.removeItem(WORKING_BRANCH_STORAGE_KEY);
  } catch (e) {}
}

export const state = () => ({
  errorAlert: null,
  successAlert: null,
  scannerData: null,
  pointsData: null,
  toastData: null,
  paymentData: null,
  paymentError: null,
  paymentResult: null,
  workingBranch: null,
  workingBranchSelectedAt: null,
  branches: [],
});

export const mutations = {
  SET_BY_KEY(state, { key, value }) {
    state[key] = value;
  },
  SET_WORKING_BRANCH(state, branch) {
    state.workingBranch = branch;
    state.workingBranchSelectedAt = branch ? Date.now() : null;
    if (branch) {
      saveToStorage({ branch, selectedAt: state.workingBranchSelectedAt });
    } else {
      clearStorage();
    }
  },
  HYDRATE_WORKING_BRANCH(state) {
    const stored = loadFromStorage();
    if (!stored) return;
    state.workingBranch = stored.branch;
    state.workingBranchSelectedAt = stored.selectedAt;
  },
  SET_BRANCHES(state, branches) {
    state.branches = branches || [];
  },
};

export const getters = {
  isWorkingBranchStale(state) {
    if (!state.workingBranchSelectedAt) return true;
    return Date.now() - state.workingBranchSelectedAt > STALE_AFTER_MS;
  },
  needsBranchSelection(state, getters) {
    return !state.workingBranch || getters.isWorkingBranchStale;
  },
  homeBranch(state, _getters, rootState) {
    const user = rootState.auth && rootState.auth.user;
    return user && user.branch ? user.branch : null;
  },
  isWorkingAwayFromHome(state, getters) {
    const home = getters.homeBranch;
    if (!home || !state.workingBranch) return false;
    return home.id !== state.workingBranch.id;
  },
};

export const actions = {
  async fetchBranches({ commit }) {
    try {
      const response = await this.$publicAxios.get('/branches');
      const branches = Array.isArray(response.data) ? response.data : [];
      commit('SET_BRANCHES', branches);
      return branches;
    } catch (e) {
      commit('SET_BRANCHES', []);
      return [];
    }
  },
  setWorkingBranch({ commit }, branch) {
    commit('SET_WORKING_BRANCH', branch);
  },
  clearWorkingBranch({ commit }) {
    commit('SET_WORKING_BRANCH', null);
  },
};
