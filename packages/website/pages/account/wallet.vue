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
                <i class="fas fa-list"></i> All
              </button>
              <button
                class="filter-chip"
                :class="{ active: selectedFilter === 'topup' }"
                @click="setFilter('topup')"
              >
                <i class="fas fa-wallet"></i> Top-ups
              </button>
              <button
                class="filter-chip"
                :class="{ active: selectedFilter === 'charge' }"
                @click="setFilter('charge')"
              >
                <i class="fas fa-credit-card"></i> Charges
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
                <i class="fas fa-list"></i> All
              </button>
              <button
                class="filter-chip"
                :class="{ active: selectedFilter === 'topup' }"
                @click="setFilter('topup')"
              >
                <i class="fas fa-wallet"></i> Top-ups
              </button>
              <button
                class="filter-chip"
                :class="{ active: selectedFilter === 'charge' }"
                @click="setFilter('charge')"
              >
                <i class="fas fa-credit-card"></i> Charges
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
        'top_up': 'Top Up',
        'payment': 'Payment',
        'refund': 'Refund',
        'bonus': 'Bonus',
        'conversion': 'Points Conversion',
        'withdrawal': 'Withdrawal',
        'adjustment': 'Adjustment',
        'transfer_in': 'Transfer In',
        'transfer_out': 'Transfer Out',
        'voucher': 'Voucher',
        'points': 'Points',
        'purchase': 'Purchase',
        'cashback': 'Cashback',
        'reward': 'Reward',
        'fee': 'Fee',
        'subscription': 'Subscription',
        'deposit': 'Deposit',
        'credit': 'Credit',
        'debit': 'Debit'
      };
      return titles[type] || 'Transaction';
    },
    getTransactionIcon(type, status) {
      // Handle failed/cancelled transactions
      if (status && ['failed', 'cancelled', 'rejected'].includes(status.toLowerCase())) {
        return 'fas fa-exclamation-circle';
      }

      // Unique icon for each transaction type (using actual database values with underscores)
      const icons = {
        'top_up': 'fas fa-wallet',
        'payment': 'fas fa-shopping-cart',
        'refund': 'fas fa-undo-alt',
        'bonus': 'fas fa-gift',
        'conversion': 'fas fa-exchange-alt',
        'withdrawal': 'fas fa-money-bill-wave',
        'adjustment': 'fas fa-balance-scale',
        'transfer_in': 'fas fa-download',
        'transfer_out': 'fas fa-upload',
        'voucher': 'fas fa-ticket-alt',
        'points': 'fas fa-star',
        'purchase': 'fas fa-shopping-bag',
        'cashback': 'fas fa-receipt',
        'reward': 'fas fa-award',
        'fee': 'fas fa-file-invoice-dollar',
        'subscription': 'fas fa-sync-alt',
        'deposit': 'fas fa-piggy-bank',
        'credit': 'fas fa-hand-holding-usd',
        'debit': 'fas fa-credit-card'
      };

      // If specific type not found, use semantic fallback based on transaction category
      if (!icons[type]) {
        const category = this.getTransactionType(type, status);
        return category === 'credit' ? 'fas fa-plus-circle' : 'fas fa-minus-circle';
      }

      return icons[type];
    },
    getTransactionType(type, status) {
      // Failed/cancelled transactions get a special type
      if (status && ['failed', 'cancelled', 'rejected'].includes(status.toLowerCase())) {
        return 'failed';
      }

      // Credit transactions (incoming money)
      if (['credit', 'top_up', 'topup', 'refund', 'bonus', 'conversion', 'voucher', 'points', 'transfer_in', 'cashback', 'reward', 'deposit'].includes(type)) {
        return 'credit';
      }

      // Debit transactions (outgoing money)
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
// Bright Theme Colors - Matching Application
$teal-primary: #1797AD;
$teal-dark: #14828E;
$teal-light: #1BA4BC;
$dark-green: #063F48;
$cream-bg: #F7F5F2;
$white: #FFFFFF;
$off-white: #FAFAF8;
$green-success: #00A862;
$red-error: #D32F2F;
$gold-accent: #CBA258;
$gray-text: #4A5568;
$gray-light: #A0AEC0;
$gray-border: #E2E8F0;

.wallet-page {
  max-width: 800px;
  margin: 0 auto;
  background: $cream-bg;
  min-height: 100vh;
  padding: 24px;
}

.page-header {
  margin-bottom: 32px;

  .page-title {
    font-size: 32px;
    font-weight: 700;
    color: $dark-green;
    margin: 0 0 8px 0;
    letter-spacing: -0.5px;
  }

  .page-subtitle {
    font-size: 15px;
    color: $gray-light;
    margin: 0;
  }
}

.balance-card {
  background: $white;
  background: -webkit-linear-gradient(135deg, $teal-primary 0%, $teal-dark 100%);
  background: linear-gradient(135deg, $teal-primary 0%, $teal-dark 100%);
  border-radius: 20px;
  padding: 36px;
  color: white;
  -webkit-box-shadow: 0 8px 24px rgba(23, 151, 173, 0.2);
  box-shadow: 0 8px 24px rgba(23, 151, 173, 0.2);
  margin-bottom: 32px;
  position: relative;
  overflow: hidden;

  &::before {
    content: '';
    position: absolute;
    top: -50%;
    right: -20%;
    width: 300px;
    height: 300px;
    background: rgba(255, 255, 255, 0.08);
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
      font-size: 22px;
      font-weight: 700;
      color: $dark-green;
      margin: 0;
      letter-spacing: -0.3px;
    }

    .transaction-count {
      font-size: 13px;
      color: $gray-light;
      background: $white;
      padding: 6px 14px;
      border-radius: 16px;
      border: 1px solid $gray-border;
      font-weight: 500;
    }
  }
}

// Filter Chips
.filter-chips {
  display: flex;
  gap: 12px;
  margin-bottom: 28px;
  flex-wrap: wrap;

  .filter-chip {
    padding: 12px 24px;
    border: 2px solid $gray-border;
    border-radius: 28px;
    background: $white;
    color: $gray-text;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.25s ease;
    display: flex;
    align-items: center;
    gap: 8px;
    -webkit-box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);

    i {
      font-size: 13px;
    }

    &:hover {
      background: $off-white;
      border-color: $teal-light;
      color: $teal-primary;
      -webkit-box-shadow: 0 4px 12px rgba(23, 151, 173, 0.12);
      box-shadow: 0 4px 12px rgba(23, 151, 173, 0.12);
    }

    &.active {
      background: $teal-primary;
      border-color: $teal-primary;
      color: white;
      -webkit-box-shadow: 0 4px 12px rgba(23, 151, 173, 0.25);
      box-shadow: 0 4px 12px rgba(23, 151, 173, 0.25);
    }
  }
}

.loading-state {
  text-align: center;
  padding: 64px 32px;

  p {
    margin-top: 16px;
    color: $gray-light;
    font-size: 15px;
  }
}

.empty-state {
  text-align: center;
  padding: 64px 32px;
  background: $white;
  border-radius: 20px;
  border: 1px solid $gray-border;

  .empty-icon {
    font-size: 64px;
    color: $gray-border;
    margin-bottom: 20px;
  }

  h4 {
    font-size: 20px;
    font-weight: 600;
    color: $gray-text;
    margin: 0 0 8px 0;
  }

  p {
    font-size: 15px;
    color: $gray-light;
    margin: 0;
  }
}

.transaction-list {
  display: flex;
  flex-direction: column;
  gap: 28px;
}

// Date Groups
.date-group {
  .date-label {
    font-size: 13px;
    font-weight: 700;
    color: $teal-primary;
    margin-bottom: 14px;
    text-transform: uppercase;
    letter-spacing: 1px;
  }

  .date-group-card {
    background: $white;
    border-radius: 20px;
    padding: 12px;
    border: 1px solid $gray-border;
    -webkit-box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
  }
}

// Transaction Rows
.transaction-row {
  background: $off-white;
  border-radius: 16px;
  padding: 18px 20px;
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 10px;
  transition: all 0.25s ease;
  border: 1px solid transparent;

  &:last-child {
    margin-bottom: 0;
  }

  &:hover {
    background: $white;
    border-color: $teal-light;
    -webkit-box-shadow: 0 4px 16px rgba(23, 151, 173, 0.12);
    box-shadow: 0 4px 16px rgba(23, 151, 173, 0.12);
    -webkit-transform: translateY(-2px);
    -ms-transform: translateY(-2px);
    transform: translateY(-2px);
  }

  .transaction-icon-wrapper {
    .transaction-icon {
      width: 52px;
      height: 52px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 22px;

      // Semantic Iconography with color logic
      &.icon-credit {
        background: rgba(0, 168, 98, 0.12);
        color: $green-success;
      }

      &.icon-debit {
        background: rgba(211, 47, 47, 0.12);
        color: $red-error;
      }

      &.icon-refund {
        background: rgba(203, 162, 88, 0.12);
        color: $gold-accent;
      }

      &.icon-failed {
        background: rgba(160, 174, 192, 0.12);
        color: $gray-light;
      }
    }
  }

  .transaction-info {
    flex: 1;
    min-width: 0; // Enable text truncation

    .transaction-title {
      font-size: 16px;
      font-weight: 600;
      color: $dark-green;
      margin: 0 0 6px 0;
      letter-spacing: -0.2px;
    }

    .transaction-date {
      font-size: 13px;
      color: $gray-light;
      margin: 0 0 4px 0;
      font-weight: 500;
    }

    .transaction-description {
      font-size: 13px;
      color: $gray-text;
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
      letter-spacing: -0.3px;
    }

    &.amount-credit {
      color: $green-success;
    }

    &.amount-debit {
      color: $red-error;
    }

    &.amount-failed {
      color: $gray-light;
    }
  }
}

.btn-load-more {
  width: 100%;
  padding: 16px 24px;
  border: 2px solid $gray-border;
  border-radius: 16px;
  background: $white;
  color: $teal-primary;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.25s ease;
  margin-top: 16px;
  -webkit-box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);

  &:hover:not(:disabled) {
    border-color: $teal-primary;
    color: white;
    background: $teal-primary;
    -webkit-box-shadow: 0 4px 12px rgba(23, 151, 173, 0.2);
    box-shadow: 0 4px 12px rgba(23, 151, 173, 0.2);
  }

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  i {
    margin-right: 8px;
  }
}

@media (max-width: 768px) {
  .wallet-page {
    padding: 16px;
    background: $cream-bg;
  }

  .page-header {
    .page-title {
      font-size: 26px;
    }

    .page-subtitle {
      font-size: 14px;
    }
  }

  .balance-card {
    padding: 28px;
    margin-bottom: 28px;
    border-radius: 18px;

    .balance-amount-wrapper {
      .currency {
        font-size: 24px;
      }

      .balance-amount {
        font-size: 36px;
      }
    }
  }

  .transaction-section {
    .section-header {
      .section-title {
        font-size: 20px;
      }
    }
  }

  .filter-chips {
    gap: 8px;

    .filter-chip {
      padding: 10px 18px;
      font-size: 13px;
    }
  }

  .transaction-list {
    gap: 20px;
  }

  .date-group-card {
    border-radius: 16px;
    padding: 8px;
  }

  .transaction-row {
    padding: 16px;
    gap: 14px;
    border-radius: 14px;

    .transaction-icon-wrapper .transaction-icon {
      width: 44px;
      height: 44px;
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
      font-size: 12px;
      margin-bottom: 10px;
    }
  }
}
</style>
