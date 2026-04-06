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
              <span class="transaction-count" v-if="!loadingTransactions">{{ filteredTransactions.length }} transactions</span>
            </div>

            <!-- Filter Chips -->
            <div class="filter-chips">
              <button
                class="filter-chip"
                :class="{ active: selectedFilter === 'all' }"
                @click="setFilter('all')"
              >
                All
              </button>
              <button
                class="filter-chip"
                :class="{ active: selectedFilter === 'topup' }"
                @click="setFilter('topup')"
              >
                <i class="fas fa-arrow-up"></i> Top-ups
              </button>
              <button
                class="filter-chip"
                :class="{ active: selectedFilter === 'charge' }"
                @click="setFilter('charge')"
              >
                <i class="fas fa-arrow-down"></i> Charges
              </button>
            </div>

            <!-- Loading State -->
            <div v-if="loadingTransactions" class="loading-state">
              <div class="spinner-border text-primary" role="status">
                <span class="sr-only">Loading...</span>
              </div>
              <p>Loading transactions...</p>
            </div>

            <!-- Empty State -->
            <div v-else-if="filteredTransactions.length === 0" class="empty-state">
              <div class="empty-icon">
                <i class="fas fa-receipt"></i>
              </div>
              <h4>No transactions yet</h4>
              <p>Your transaction history will appear here</p>
            </div>

            <!-- Transaction List -->
            <div v-else class="transaction-list">
              <!-- Date Groups -->
              <div v-for="(transactions, dateLabel) in groupedTransactions" :key="dateLabel" class="date-group">
                <div class="date-label">{{ dateLabel }}</div>
                <div class="date-group-card">
                  <div
                    v-for="transaction in transactions"
                    :key="transaction.id"
                    class="transaction-row"
                  >
                    <div class="transaction-icon-wrapper">
                      <div class="transaction-icon" :class="`icon-${getTransactionType(transaction.type, transaction.status)}`">
                        <i :class="getTransactionIcon(transaction.type, transaction.status)"></i>
                      </div>
                    </div>
                    <div class="transaction-info">
                      <h4 class="transaction-title">{{ getTransactionTitle(transaction.type) }}</h4>
                      <p class="transaction-date">{{ formatDate(transaction.createdAt) }}</p>
                      <p class="transaction-description" v-if="transaction.description">
                        {{ transaction.description }}
                      </p>
                    </div>
                    <div class="transaction-amount" :class="`amount-${getTransactionType(transaction.type, transaction.status)}`">
                      <span class="amount-sign">{{ getAmountSign(transaction.type) }}</span>
                      <span class="amount-value">฿{{ formatCurrency(transaction.amount) }}</span>
                    </div>
                  </div>
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

            <!-- Filter Chips -->
            <div class="filter-chips">
              <button
                class="filter-chip"
                :class="{ active: selectedFilter === 'all' }"
                @click="setFilter('all')"
              >
                All
              </button>
              <button
                class="filter-chip"
                :class="{ active: selectedFilter === 'topup' }"
                @click="setFilter('topup')"
              >
                <i class="fas fa-arrow-up"></i> Top-ups
              </button>
              <button
                class="filter-chip"
                :class="{ active: selectedFilter === 'charge' }"
                @click="setFilter('charge')"
              >
                <i class="fas fa-arrow-down"></i> Charges
              </button>
            </div>

            <!-- Loading State -->
            <div v-if="loadingTransactions" class="loading-state">
              <div class="spinner-border text-primary" role="status">
                <span class="sr-only">Loading...</span>
              </div>
              <p>Loading...</p>
            </div>

            <!-- Empty State -->
            <div v-else-if="filteredTransactions.length === 0" class="empty-state">
              <div class="empty-icon">
                <i class="fas fa-receipt"></i>
              </div>
              <h4>No transactions</h4>
              <p>Your history will appear here</p>
            </div>

            <!-- Transaction List -->
            <div v-else class="transaction-list">
              <!-- Date Groups -->
              <div v-for="(transactions, dateLabel) in groupedTransactions" :key="dateLabel" class="date-group">
                <div class="date-label">{{ dateLabel }}</div>
                <div class="date-group-card">
                  <div
                    v-for="transaction in transactions"
                    :key="transaction.id"
                    class="transaction-row"
                  >
                    <div class="transaction-icon-wrapper">
                      <div class="transaction-icon" :class="`icon-${getTransactionType(transaction.type, transaction.status)}`">
                        <i :class="getTransactionIcon(transaction.type, transaction.status)"></i>
                      </div>
                    </div>
                    <div class="transaction-info">
                      <h4 class="transaction-title">{{ getTransactionTitle(transaction.type) }}</h4>
                      <p class="transaction-date">{{ formatDate(transaction.createdAt) }}</p>
                    </div>
                    <div class="transaction-amount" :class="`amount-${getTransactionType(transaction.type, transaction.status)}`">
                      <span class="amount-sign">{{ getAmountSign(transaction.type) }}</span>
                      <span class="amount-value">฿{{ formatCurrency(transaction.amount) }}</span>
                    </div>
                  </div>
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
    selectedFilter: 'all', // all, topup, charge
  }),
  computed: {
    filteredTransactions() {
      if (this.selectedFilter === 'all') {
        return this.transactions;
      }

      return this.transactions.filter(transaction => {
        const type = this.getTransactionType(transaction.type, transaction.status);
        if (this.selectedFilter === 'topup') {
          return type === 'credit';
        } else if (this.selectedFilter === 'charge') {
          return type === 'debit';
        }
        return true;
      });
    },
    groupedTransactions() {
      return this.groupTransactionsByDate(this.filteredTransactions);
    }
  },
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
    getTransactionIcon(type, status) {
      // Handle failed/cancelled transactions
      if (status && ['failed', 'cancelled', 'rejected'].includes(status.toLowerCase())) {
        return 'fas fa-times-circle';
      }

      const icons = {
        'credit': 'fas fa-arrow-up',
        'debit': 'fas fa-arrow-down',
        'payment': 'fas fa-arrow-down',
        'topup': 'fas fa-plus',
        'refund': 'fas fa-undo-alt',
        'voucher': 'fas fa-plus',
        'points': 'fas fa-plus',
        'transfer_in': 'fas fa-arrow-up',
        'transfer_out': 'fas fa-arrow-down'
      };
      return icons[type] || 'fas fa-exchange-alt';
    },
    getTransactionType(type, status) {
      // Failed/cancelled transactions get a special type
      if (status && ['failed', 'cancelled', 'rejected'].includes(status.toLowerCase())) {
        return 'failed';
      }

      if (['credit', 'topup', 'refund', 'voucher', 'points', 'transfer_in'].includes(type)) {
        return 'credit';
      }
      return 'debit';
    },
    getAmountSign(type) {
      return this.getTransactionType(type) === 'credit' ? '+' : '-';
    },
    setFilter(filter) {
      this.selectedFilter = filter;
    },
    groupTransactionsByDate(transactions) {
      const groups = {};
      const today = this.$moment().startOf('day');
      const yesterday = this.$moment().subtract(1, 'day').startOf('day');

      transactions.forEach(transaction => {
        const transactionDate = this.$moment(transaction.createdAt).startOf('day');
        let dateLabel;

        if (transactionDate.isSame(today, 'day')) {
          dateLabel = 'Today';
        } else if (transactionDate.isSame(yesterday, 'day')) {
          dateLabel = 'Yesterday';
        } else {
          dateLabel = this.$moment(transaction.createdAt).format('MMMM DD, YYYY');
        }

        if (!groups[dateLabel]) {
          groups[dateLabel] = [];
        }
        groups[dateLabel].push(transaction);
      });

      return groups;
    }
  },
};
</script>

<style lang="scss" scoped>
// Dark Green Theme Colors
$emerald-primary: #047857;
$emerald-dark: #065f46;
$forest-bg: #022c22;
$forest-surface: #064e3b;
$forest-surface-light: #065f46;
$green-success: #10b981;
$red-error: #ef4444;
$teal-refund: #14b8a6;
$gray-muted: #6b7280;

.wallet-page {
  max-width: 800px;
  margin: 0 auto;
  background: $forest-bg;
  min-height: 100vh;
  padding: 24px;
}

.page-header {
  margin-bottom: 32px;

  .page-title {
    font-size: 28px;
    font-weight: 700;
    color: #e5e7eb;
    margin: 0 0 8px 0;
  }

  .page-subtitle {
    font-size: 14px;
    color: #9ca3af;
    margin: 0;
  }
}

.balance-card {
  background: $emerald-primary;
  background: -webkit-linear-gradient(135deg, $emerald-primary 0%, $emerald-dark 100%);
  background: linear-gradient(135deg, $emerald-primary 0%, $emerald-dark 100%);
  border-radius: 16px;
  padding: 32px;
  color: white;
  -webkit-box-shadow: 0 10px 30px rgba(4, 120, 87, 0.3);
  box-shadow: 0 10px 30px rgba(4, 120, 87, 0.3);
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
    margin-bottom: 20px;

    .section-title {
      font-size: 20px;
      font-weight: 600;
      color: #e5e7eb;
      margin: 0;
    }

    .transaction-count {
      font-size: 13px;
      color: #d1d5db;
      background: $forest-surface;
      padding: 4px 12px;
      border-radius: 12px;
    }
  }
}

// Filter Chips
.filter-chips {
  display: flex;
  gap: 12px;
  margin-bottom: 24px;
  flex-wrap: wrap;

  .filter-chip {
    padding: 10px 20px;
    border: 2px solid $forest-surface-light;
    border-radius: 24px;
    background: $forest-surface;
    color: #9ca3af;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
    display: flex;
    align-items: center;
    gap: 6px;

    i {
      font-size: 12px;
    }

    &:hover {
      background: $forest-surface-light;
      color: #d1d5db;
      border-color: $emerald-primary;
    }

    &.active {
      background: $emerald-primary;
      border-color: $emerald-primary;
      color: white;
    }
  }
}

.loading-state {
  text-align: center;
  padding: 64px 32px;

  p {
    margin-top: 16px;
    color: #9ca3af;
    font-size: 14px;
  }
}

.empty-state {
  text-align: center;
  padding: 64px 32px;
  background: $forest-surface;
  border-radius: 16px;

  .empty-icon {
    font-size: 64px;
    color: $forest-surface-light;
    margin-bottom: 16px;
  }

  h4 {
    font-size: 18px;
    font-weight: 600;
    color: #d1d5db;
    margin: 0 0 8px 0;
  }

  p {
    font-size: 14px;
    color: #9ca3af;
    margin: 0;
  }
}

.transaction-list {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

// Date Groups
.date-group {
  .date-label {
    font-size: 14px;
    font-weight: 600;
    color: #10b981;
    margin-bottom: 12px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .date-group-card {
    background: $forest-surface;
    border-radius: 16px;
    padding: 8px;
    -webkit-box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
  }
}

// Transaction Rows
.transaction-row {
  background: $forest-surface-light;
  border-radius: 12px;
  padding: 16px;
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 8px;
  transition: all 0.2s ease;

  &:last-child {
    margin-bottom: 0;
  }

  &:hover {
    -webkit-box-shadow: 0 4px 12px rgba(4, 120, 87, 0.2);
    box-shadow: 0 4px 12px rgba(4, 120, 87, 0.2);
    -webkit-transform: translateY(-2px);
    -ms-transform: translateY(-2px);
    transform: translateY(-2px);
  }

  .transaction-icon-wrapper {
    .transaction-icon {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 20px;

      // Semantic Iconography with color logic
      &.icon-credit {
        background: rgba(16, 185, 129, 0.15);
        color: $green-success;
      }

      &.icon-debit {
        background: rgba(239, 68, 68, 0.15);
        color: $red-error;
      }

      &.icon-refund {
        background: rgba(20, 184, 166, 0.15);
        color: $teal-refund;
      }

      &.icon-failed {
        background: rgba(107, 114, 128, 0.15);
        color: $gray-muted;
      }
    }
  }

  .transaction-info {
    flex: 1;
    min-width: 0; // Enable text truncation

    .transaction-title {
      font-size: 16px;
      font-weight: 600;
      color: #e5e7eb;
      margin: 0 0 4px 0;
    }

    .transaction-date {
      font-size: 13px;
      color: #9ca3af;
      margin: 0 0 4px 0;
    }

    .transaction-description {
      font-size: 13px;
      color: #6b7280;
      margin: 0;
      // Text truncation
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      max-width: 100%;
    }
  }

  .transaction-amount {
    display: flex;
    align-items: baseline;
    gap: 4px;
    font-weight: 700;
    flex-shrink: 0;

    .amount-sign {
      font-size: 18px;
    }

    .amount-value {
      font-size: 20px;
    }

    &.amount-credit {
      color: $green-success;
    }

    &.amount-debit {
      color: $red-error;
    }

    &.amount-failed {
      color: $gray-muted;
    }
  }
}

.btn-load-more {
  width: 100%;
  padding: 14px 24px;
  border: 2px solid $forest-surface-light;
  border-radius: 12px;
  background: $forest-surface;
  color: #d1d5db;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  margin-top: 12px;

  &:hover:not(:disabled) {
    border-color: $emerald-primary;
    color: white;
    background: $emerald-dark;
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
  .wallet-page {
    padding: 16px;
  }

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

  .filter-chips {
    gap: 8px;

    .filter-chip {
      padding: 8px 16px;
      font-size: 13px;
    }
  }

  .transaction-row {
    padding: 14px;
    gap: 12px;

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

      .transaction-description {
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

  .date-group {
    .date-label {
      font-size: 13px;
    }
  }
}
</style>
