export const state = () => ({
  errorAlert: null,
  successAlert: null,
  scannerData: null,
  pointsData: null,
  toastData: null,
  paymentData: null,
  paymentError: null,
  paymentResult: null,
})

export const mutations = {
  SET_BY_KEY (state, { key, value }) {
    state[key] = value
  }
}

export const actions = {}
