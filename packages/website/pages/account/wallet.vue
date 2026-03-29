<template>
  <div>
    <AccountSettings>
      <template v-slot:desktop>
        <div class="wallet-page">
          <!-- Header -->
          <div class="page-header">
            <h2 class="page-title">My Wallet</h2>
            <p class="page-subtitle">Manage your balance and transactions</p>
          </div>

          <!-- Balance Card -->
          <div class="balance-card">
            <div class="balance-card-header">
              <div class="balance-icon">
                <i class="fas fa-wallet"></i>
              </div>
              <span class="balance-label">Available Balance</span>
            </div>
            <div class="balance-amount-wrapper">
              <span class="currency">฿</span>
              <span class="balance-amount" v-if="!loadingBalance">{{ formatCurrency(walletBalance) }}</span>
              <span class="spinner-border spinner-border-sm" role="status" v-if="loadingBalance"></span>
            </div>
            <div class="balance-updated">Last updated: {{ lastUpdated }}</div>
          </div>

          <!-- Transaction Section -->
          <div class="transaction-section">
            <div class="section-header">
              <h3 class="section-title">Recent Transactions</h3>
              <span class="transaction-count" v-if="!loadingTransactions">{{ transactions.length }} transactions</span>
            </div>

            <!-- Loading State -->
            <div v-if="loadingTransactions" class="loading-state">
              <div class="spinner-border text-primary" role="status">
                <span class="sr-only">Loading...</span>
              </div>
              <p>Loading transactions...</p>
            </div>

            <!-- Empty State -->
            <div v-else-if="transactions.length === 0" class="empty-state">
              <div class="empty-icon">
                <i class="fas fa-receipt"></i>
              </div>
              <h4>No transactions yet</h4>
              <p>Your transaction history will appear here</p>
            </div>

            <!-- Transaction List -->
            <div v-else class="transaction-list">
              <div
                v-for="transaction in transactions"
                :key="transaction.id"
                class="transaction-card"
                :class="`transaction-${getTransactionType(transaction.type)}`"
              >
                <div class="transaction-icon-wrapper">
                  <div class="transaction-icon" :class="`icon-${getTransactionType(transaction.type)}`">
                    <i :class="getTransactionIcon(transaction.type)"></i>
                  </div>
                </div>
                <div class="transaction-info">
                  <h4 class="transaction-title">{{ getTransactionTitle(transaction.type) }}</h4>
                  <p class="transaction-date">{{ formatDate(transaction.createdAt) }}</p>
                  <p class="transaction-description" v-if="transaction.description">
                    {{ transaction.description }}
                  </p>
                </div>
                <div class="transaction-amount" :class="`amount-${getTransactionType(transaction.type)}`">
                  <span class="amount-sign">{{ getAmountSign(transaction.type) }}</span>
                  <span class="amount-value">฿{{ formatCurrency(transaction.amount) }}</span>
                </div>
              </div>

              <!-- Load More Button -->
              <button
                v-if="hasMoreTransactions"
                @click="loadMoreTransactions"
                class="btn-load-more"
                :disabled="loadingMore"
              >
                <span class="spinner-border spinner-border-sm" role="status" v-if="loadingMore"></span>
                <span v-else><i class="fas fa-sync-alt"></i> Load More</span>
              </button>
            </div>
          </div>
        </div>
      </template>

      <template v-slot:mobile>
        <div class="wallet-page">
          <!-- Header -->
          <div class="page-header">
            <h2 class="page-title">My Wallet</h2>
            <p class="page-subtitle">Manage your balance</p>
          </div>

          <!-- Balance Card -->
          <div class="balance-card">
            <div class="balance-card-header">
              <div class="balance-icon">
                <i class="fas fa-wallet"></i>
              </div>
              <span class="balance-label">Available Balance</span>
            </div>
            <div class="balance-amount-wrapper">
              <span class="currency">฿</span>
              <span class="balance-amount" v-if="!loadingBalance">{{ formatCurrency(walletBalance) }}</span>
              <span class="spinner-border spinner-border-sm" role="status" v-if="loadingBalance"></span>
            </div>
            <div class="balance-updated">Last updated: {{ lastUpdated }}</div>
          </div>

          <!-- Transaction Section -->
          <div class="transaction-section">
            <div class="section-header">
              <h3 class="section-title">Transactions</h3>
            </div>

            <!-- Loading State -->
            <div v-if="loadingTransactions" class="loading-state">
              <div class="spinner-border text-primary" role="status">
                <span class="sr-only">Loading...</span>
              </div>
              <p>Loading...</p>
            </div>

            <!-- Empty State -->
            <div v-else-if="transactions.length === 0" class="empty-state">
              <div class="empty-icon">
                <i class="fas fa-receipt"></i>
              </div>
              <h4>No transactions</h4>
              <p>Your history will appear here</p>
            </div>

            <!-- Transaction List -->
            <div v-else class="transaction-list">
              <div
                v-for="transaction in transactions"
                :key="transaction.id"
                class="transaction-card"
                :class="`transaction-${getTransactionType(transaction.type)}`"
              >
                <div class="transaction-icon-wrapper">
                  <div class="transaction-icon" :class="`icon-${getTransactionType(transaction.type)}`">
                    <i :class="getTransactionIcon(transaction.type)"></i>
                  </div>
                </div>
                <div class="transaction-info">
                  <h4 class="transaction-title">{{ getTransactionTitle(transaction.type) }}</h4>
                  <p class="transaction-date">{{ formatDate(transaction.createdAt) }}</p>
                </div>
                <div class="transaction-amount" :class="`amount-${getTransactionType(transaction.type)}`">
                  <span class="amount-sign">{{ getAmountSign(transaction.type) }}</span>
                  <span class="amount-value">฿{{ formatCurrency(transaction.amount) }}</span>
                </div>
              </div>

              <!-- Load More Button -->
              <button
                v-if="hasMoreTransactions"
                @click="loadMoreTransactions"
                class="btn-load-more"
                :disabled="loadingMore"
              >
                <span class="spinner-border spinner-border-sm" role="status" v-if="loadingMore"></span>
                <span v-else><i class="fas fa-sync-alt"></i> Load More</span>
              </button>
            </div>
          </div>
        </div>
      </template>
    </AccountSettings>
  </div>
</template>

<script>
export default {
  head() {
    return {
      title: "Wallet - Account Settings",
    };
  },
  middleware: "auth",
  layout: "w_nav",
  data: () => ({
    loadingBalance: true,
    loadingTransactions: true,
    loadingMore: false,
    walletBalance: 0,
    transactions: [],
    currentPage: 1,
    pageSize: 10,
    hasMoreTransactions: false,
    lastUpdated: '',
  }),
  async mounted() {
    await this.fetchWalletBalance();
    await this.fetchTransactions();
  },
  methods: {
    async fetchWalletBalance() {
      this.loadingBalance = true;
      try {
        const response = await this.__getWalletBalance();
        // Backend wraps response in {success, data: {balance, ...}}
        const data = response.data || response;
        this.walletBalance = data.balance || 0;
        this.lastUpdated = this.$moment().format('MMM DD, YYYY HH:mm');
      } catch (error) {
        console.error('Error fetching wallet balance:', error);
        this.__showToast({
          title: "Error",
          description: "Failed to load wallet balance",
          type: "danger",
        });
      } finally {
        this.loadingBalance = false;
      }
    },
    async fetchTransactions(page = 1) {
      this.loadingTransactions = page === 1;
      this.loadingMore = page > 1;

      try {
        const response = await this.__getWalletTransactions({
          _limit: this.pageSize,
          _start: (page - 1) * this.pageSize,
          _sort: 'created_at:DESC'
        });

        // Backend wraps response in {success, data: {transactions, pagination}}
        const data = response.data || response;
        const newTransactions = data.transactions || data || [];

        if (page === 1) {
          this.transactions = newTransactions;
        } else {
          this.transactions = [...this.transactions, ...newTransactions];
        }

        this.hasMoreTransactions = newTransactions.length === this.pageSize;
        this.currentPage = page;
      } catch (error) {
        console.error('Error fetching transactions:', error);
        this.__showToast({
          title: "Error",
          description: "Failed to load transactions",
          type: "danger",
        });
      } finally {
        this.loadingTransactions = false;
        this.loadingMore = false;
      }
    },
    async loadMoreTransactions() {
      await this.fetchTransactions(this.currentPage + 1);
    },
    formatCurrency(amount) {
      return new Intl.NumberFormat('th-TH', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      }).format(amount);
    },
    formatDate(date) {
      return this.$moment(date).format('MMM DD, YYYY HH:mm');
    },
    getTransactionTitle(type) {
      const titles = {
        'credit': 'Top Up',
        'debit': 'Payment',
        'payment': 'Payment',
        'topup': 'Top Up',
        'refund': 'Refund',
        'voucher': 'Voucher',
        'points': 'Points Converted',
        'transfer_in': 'Transfer In',
        'transfer_out': 'Transfer Out'
      };
      return titles[type] || 'Transaction';
    },
    getTransactionIcon(type) {
      const icons = {
        'credit': 'fas fa-arrow-down',
        'debit': 'fas fa-arrow-up',
        'payment': 'fas fa-shopping-bag',
        'topup': 'fas fa-plus-circle',
        'refund': 'fas fa-undo',
        'voucher': 'fas fa-ticket-alt',
        'points': 'fas fa-star',
        'transfer_in': 'fas fa-arrow-circle-down',
        'transfer_out': 'fas fa-arrow-circle-up'
      };
      return icons[type] || 'fas fa-exchange-alt';
    },
    getTransactionType(type) {
      if (['credit', 'topup', 'refund', 'voucher', 'points', 'transfer_in'].includes(type)) {
        return 'credit';
      }
      return 'debit';
    },
    getAmountSign(type) {
      return this.getTransactionType(type) === 'credit' ? '+' : '-';
    }
  },
};
</script>

<style lang="scss" scoped>
.wallet-page {
  max-width: 800px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 32px;

  .page-title {
    font-size: 28px;
    font-weight: 700;
    color: #2d3748;
    margin: 0 0 8px 0;
  }

  .page-subtitle {
    font-size: 14px;
    color: #718096;
    margin: 0;
  }
}

.balance-card {
  background: #1797ad; /* Fallback */
  background: -webkit-linear-gradient(135deg, #1797ad 0%, #14828e 100%); /* Safari 5.1-6 */
  background: linear-gradient(135deg, #1797ad 0%, #14828e 100%);
  border-radius: 16px;
  padding: 32px;
  color: white;
  -webkit-box-shadow: 0 10px 30px rgba(23, 151, 173, 0.2);
  box-shadow: 0 10px 30px rgba(23, 151, 173, 0.2);
  margin-bottom: 40px;
  position: relative;
  overflow: hidden;

  &::before {
    content: '';
    position: absolute;
    top: -50%;
    right: -20%;
    width: 300px;
    height: 300px;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 50%;
  }

  .balance-card-header {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 20px;
    position: relative;
    z-index: 1;

    .balance-icon {
      width: 40px;
      height: 40px;
      background: rgba(255, 255, 255, 0.2);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 18px;
    }

    .balance-label {
      font-size: 15px;
      font-weight: 500;
      opacity: 0.95;
    }
  }

  .balance-amount-wrapper {
    display: flex;
    align-items: baseline;
    gap: 8px;
    margin-bottom: 12px;
    position: relative;
    z-index: 1;

    .currency {
      font-size: 32px;
      font-weight: 600;
      opacity: 0.9;
    }

    .balance-amount {
      font-size: 48px;
      font-weight: 700;
      line-height: 1;
    }
  }

  .balance-updated {
    font-size: 13px;
    opacity: 0.8;
    position: relative;
    z-index: 1;
  }
}

.transaction-section {
  .section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24px;

    .section-title {
      font-size: 20px;
      font-weight: 600;
      color: #2d3748;
      margin: 0;
    }

    .transaction-count {
      font-size: 13px;
      color: #718096;
      background: #f7fafc;
      padding: 4px 12px;
      border-radius: 12px;
    }
  }
}

.loading-state {
  text-align: center;
  padding: 64px 32px;

  p {
    margin-top: 16px;
    color: #718096;
    font-size: 14px;
  }
}

.empty-state {
  text-align: center;
  padding: 64px 32px;

  .empty-icon {
    font-size: 64px;
    color: #e2e8f0;
    margin-bottom: 16px;
  }

  h4 {
    font-size: 18px;
    font-weight: 600;
    color: #4a5568;
    margin: 0 0 8px 0;
  }

  p {
    font-size: 14px;
    color: #a0aec0;
    margin: 0;
  }
}

.transaction-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.transaction-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 16px;
  transition: all 0.2s ease;

  &:hover {
    -webkit-box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
    -webkit-transform: translateY(-2px);
    -ms-transform: translateY(-2px);
    transform: translateY(-2px);
  }

  .transaction-icon-wrapper {
    .transaction-icon {
      width: 48px;
      height: 48px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 20px;

      &.icon-credit {
        background: rgba(72, 187, 120, 0.1);
        color: #38a169;
      }

      &.icon-debit {
        background: rgba(245, 101, 101, 0.1);
        color: #e53e3e;
      }
    }
  }

  .transaction-info {
    flex: 1;

    .transaction-title {
      font-size: 16px;
      font-weight: 600;
      color: #2d3748;
      margin: 0 0 4px 0;
    }

    .transaction-date {
      font-size: 13px;
      color: #a0aec0;
      margin: 0;
    }

    .transaction-description {
      font-size: 13px;
      color: #718096;
      margin: 4px 0 0 0;
    }
  }

  .transaction-amount {
    display: flex;
    align-items: baseline;
    gap: 4px;
    font-weight: 700;

    .amount-sign {
      font-size: 18px;
    }

    .amount-value {
      font-size: 20px;
    }

    &.amount-credit {
      color: #38a169;
    }

    &.amount-debit {
      color: #e53e3e;
    }
  }
}

.btn-load-more {
  width: 100%;
  padding: 14px 24px;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  background: white;
  color: #4a5568;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  margin-top: 12px;

  &:hover:not(:disabled) {
    border-color: #1797ad;
    color: #1797ad;
    background: rgba(23, 151, 173, 0.05);
  }

  &:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  i {
    margin-right: 8px;
  }
}

@media (max-width: 768px) {
  .balance-card {
    padding: 24px;
    margin-bottom: 32px;

    .balance-amount-wrapper {
      .currency {
        font-size: 24px;
      }

      .balance-amount {
        font-size: 36px;
      }
    }
  }

  .transaction-card {
    padding: 16px;

    .transaction-icon-wrapper .transaction-icon {
      width: 40px;
      height: 40px;
      font-size: 18px;
    }

    .transaction-info {
      .transaction-title {
        font-size: 15px;
      }

      .transaction-date {
        font-size: 12px;
      }
    }

    .transaction-amount {
      .amount-sign {
        font-size: 16px;
      }

      .amount-value {
        font-size: 18px;
      }
    }
  }
}
</style>
