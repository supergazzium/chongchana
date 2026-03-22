import Vue from 'vue'

const readingTime = require('reading-time')

Vue.mixin({
  methods: {
    async __updateUser(data) {
      let user = this.$store.state.auth.user
      let token = this.$auth.strategy.token.get()

      try {
        let response = await this.$axios.$put(`/users/${user.id}`, data, {
          headers: {
            Authorization: `${token}`
          }
        })
        await this.$auth.fetchUser()
        return response
      } catch (err) {
        console.log(err)
        throw err
      }
    },
    async __toastAlert(type, data) {
      switch (type) {
        case 'error':
          console.log('Show error alert')
          this.$store.commit('SET_BY_KEY', {
            key: 'errorAlert',
            value: data
          })
          break
        case 'success':
          console.log('Show success alert')
          this.$store.commit('SET_BY_KEY', {
            key: 'successAlert',
            value: data
          })
          break
      }
    },
    __getImageURL(path) {
      // Use runtime config for dynamic backend URL
      const baseURL = this.$config.axios?.baseURL || process.env.BASE_URL || 'http://localhost:7001'
      return `${baseURL}${path}`
    },
    async __changeProfileImage(files) {
      this.profileImageLoading = true
      let submitData = new FormData()
      submitData.append('id', this.$store.state.auth.user.id)
      submitData.append('files', files[0])

      let token = this.$auth.strategy.token.get()

      try {
        let response = await this.$axios.$post(
          '/api/change-profile-image',
          submitData,
          {
            headers: {
              'Content-Type': 'multipart/form-data',
              Authorization: `${token}`
            }
          }
        )
        this.activeComponent += 1
        this.success = true

        await this.$auth.fetchUser()
        // this.__toastAlert('success', {
        //   title: 'Update Successfully',
        //   description: 'Successfully updating your new profile image'
        // })
        this.__showToast({
          title: 'Update Successfully',
          description: 'Successfully updating your new profile image',
          type: 'primary'
        })
        this.profileImageLoading = false
      } catch (err) {
        console.log(err)
        // this.__toastAlert('error', {
        //   title: 'Update Failed',
        //   description: 'Fail to update your new profile image.'
        // })
        this.__showToast({
          title: 'Update Failed',
          description: 'Fail to update your new profile image',
          type: 'danger'
        })
        this.profileImageLoading = false
        // this.$refs.errorAlert.toast()
      }
    },
    __showToast({ title = '', description = '', type = 'primary' }) {
      let toastContainer = document.getElementById('toastContainer')

      if (!toastContainer) {
        console.log('no toastContainer')
        toastContainer = document.createElement('div')
        toastContainer.className = `toast-container`
        toastContainer.id = 'toastContainer'
        document.body.appendChild(toastContainer)
      }

      // Create toast elements using DOM API to prevent XSS
      let newToastDiv = document.createElement('div')
      newToastDiv.className = `toast align-items-center text-white bg-${type} border-0`

      let flexDiv = document.createElement('div')
      flexDiv.className = 'd-flex'

      let toastBody = document.createElement('div')
      toastBody.className = 'toast-body'

      let titleElement = document.createElement('strong')
      titleElement.className = '_dp-b'
      titleElement.textContent = title // Safe - uses textContent instead of innerHTML

      let descElement = document.createElement('span')
      descElement.textContent = description // Safe - uses textContent instead of innerHTML

      let closeButton = document.createElement('button')
      closeButton.type = 'button'
      closeButton.className = 'btn-close btn-close-white me-2 m-auto'
      closeButton.setAttribute('data-bs-dismiss', 'toast')
      closeButton.setAttribute('aria-label', 'Close')

      toastBody.appendChild(titleElement)
      toastBody.appendChild(descElement)
      flexDiv.appendChild(toastBody)
      flexDiv.appendChild(closeButton)
      newToastDiv.appendChild(flexDiv)

      toastContainer.appendChild(newToastDiv)
      let newToast = new bootstrap.Toast(newToastDiv, {
        delay: 3000,
      })
      newToast.show()
    },
    __calculateReadingTime(content) {
      const stats = readingTime(content)
      return stats ? `${Math.ceil(stats.minutes)} MINS TO READ` : ''
    },

    // ==================== WALLET API METHODS ====================

    /**
     * Get wallet balance
     * @returns {Promise} Balance data
     */
    async __getWalletBalance() {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$get('/wallet/balance', {
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error fetching wallet balance:', error)
        throw error
      }
    },

    /**
     * Get wallet transactions
     * @param {Object} params - Query parameters (limit, start, sort)
     * @returns {Promise} Transactions list
     */
    async __getWalletTransactions(params = {}) {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$get('/wallet/transactions', {
          params,
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error fetching transactions:', error)
        throw error
      }
    },

    /**
     * Top up wallet
     * @param {Object} data - Top up data (amount, paymentMethod, etc.)
     * @returns {Promise} Top up response
     */
    async __walletTopUp(data) {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$post('/wallet/top-up', data, {
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error topping up wallet:', error)
        throw error
      }
    },

    /**
     * Make a payment from wallet
     * @param {Object} data - Payment data (amount, description, etc.)
     * @returns {Promise} Payment response
     */
    async __walletPay(data) {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$post('/wallet/pay', data, {
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error making payment:', error)
        throw error
      }
    },

    /**
     * Redeem voucher
     * @param {Object} data - Voucher data (code)
     * @returns {Promise} Redemption response
     */
    async __redeemVoucher(data) {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$post('/wallet/voucher/redeem', data, {
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error redeeming voucher:', error)
        throw error
      }
    },

    /**
     * Convert points to wallet balance
     * @param {Object} data - Conversion data (points)
     * @returns {Promise} Conversion response
     */
    async __convertPoints(data) {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$post('/wallet/points/convert', data, {
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error converting points:', error)
        throw error
      }
    },

    /**
     * Get wallet settings
     * @returns {Promise} Settings data
     */
    async __getWalletSettings() {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$get('/wallet/settings', {
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error fetching wallet settings:', error)
        throw error
      }
    },

    // ==================== PAYMENT API METHODS ====================

    /**
     * Get available payment methods
     * @returns {Promise} Payment methods list
     */
    async __getPaymentMethods() {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$get('/wallet/payment/methods', {
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error fetching payment methods:', error)
        throw error
      }
    },

    /**
     * Create payment token (Omise)
     * @param {Object} data - Card/payment data
     * @returns {Promise} Token response
     */
    async __createPaymentToken(data) {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$post('/wallet/payment/create-token', data, {
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error creating payment token:', error)
        throw error
      }
    },

    /**
     * Create charge from token
     * @param {Object} data - Charge data (token, amount, etc.)
     * @returns {Promise} Charge response
     */
    async __createCharge(data) {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$post('/wallet/payment/create-charge', data, {
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error creating charge:', error)
        throw error
      }
    },

    /**
     * Create payment source (for QR/mobile banking)
     * @param {Object} data - Source data (type, amount, etc.)
     * @returns {Promise} Source response
     */
    async __createPaymentSource(data) {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$post('/wallet/payment/create-source', data, {
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error creating payment source:', error)
        throw error
      }
    },

    /**
     * Check payment status
     * @param {String} chargeId - Charge ID to check
     * @returns {Promise} Payment status
     */
    async __checkPaymentStatus(chargeId) {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$get(`/wallet/payment/status/${chargeId}`, {
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error checking payment status:', error)
        throw error
      }
    },

    // ==================== TRANSFER API METHODS ====================

    /**
     * Lookup user for transfer
     * @param {Object} data - User identifier (phone or email)
     * @returns {Promise} User data
     */
    async __lookupUser(data) {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$post('/wallet/lookup-user', data, {
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error looking up user:', error)
        throw error
      }
    },

    /**
     * Initiate wallet transfer
     * @param {Object} data - Transfer data (recipientId, amount, etc.)
     * @returns {Promise} Transfer response
     */
    async __initiateTransfer(data) {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$post('/wallet/transfer', data, {
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error initiating transfer:', error)
        throw error
      }
    },

    /**
     * Get transfer history
     * @param {Object} params - Query parameters (limit, start, type)
     * @returns {Promise} Transfer history
     */
    async __getTransferHistory(params = {}) {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$get('/wallet/transfers', {
          params,
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error fetching transfer history:', error)
        throw error
      }
    },

    /**
     * Get transfer details
     * @param {String} transferId - Transfer ID
     * @returns {Promise} Transfer details
     */
    async __getTransferDetails(transferId) {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$get(`/wallet/transfer/${transferId}`, {
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error fetching transfer details:', error)
        throw error
      }
    },

    // ==================== PAYMENT QR API METHODS ====================

    /**
     * Generate payment QR code
     * @param {Object} data - QR data (amount, purpose, etc.)
     * @returns {Promise} QR code response
     */
    async __generatePaymentQR(data) {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$post('/wallet/payment-qr/generate', data, {
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error generating payment QR:', error)
        throw error
      }
    },

    /**
     * Validate payment QR code
     * @param {Object} data - QR token data
     * @returns {Promise} Validation response
     * NOTE: This endpoint is public (no auth required) - handled by isPublicPaymentQR policy
     */
    async __validatePaymentQR(data) {
      try {
        const response = await this.$axios.$post('/wallet/payment-qr/validate', data)
        return response
      } catch (error) {
        console.error('Error validating payment QR:', error)
        throw error
      }
    },

    /**
     * Process payment via QR
     * @param {Object} data - Payment data (token, amount, etc.)
     * @returns {Promise} Payment response
     * NOTE: This endpoint is public (no auth required) - handled by isPublicPaymentQR policy
     */
    async __processQRPayment(data) {
      try {
        const response = await this.$axios.$post('/wallet/payment-qr/pay', data)
        return response
      } catch (error) {
        console.error('Error processing QR payment:', error)
        throw error
      }
    },

    /**
     * Get payment QR history
     * @param {Object} params - Query parameters
     * @returns {Promise} QR payment history
     */
    async __getPaymentQRHistory(params = {}) {
      try {
        let token = this.$auth.strategy.token.get()
        const response = await this.$axios.$get('/wallet/payment-qr/history', {
          params,
          headers: {
            Authorization: `${token}`
          }
        })
        return response
      } catch (error) {
        console.error('Error fetching QR payment history:', error)
        throw error
      }
    },
  },
})
