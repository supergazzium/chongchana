<template>
  <div class="wallet-page-container">
    <Breadcrumb :items="breadcrumbs" />

    <!-- Page Header -->
    <div class="wallet-page-header">
      <div>
        <h1>Wallet Management</h1>
        <p class="subtitle">Manage user wallets, balances, and transactions</p>
      </div>
      <div class="header-actions">
        <button @click="exportData" class="wallet-btn secondary">
          <i class="fas fa-download"></i>
          Export CSV
        </button>
        <nuxt-link to="/wallets/settings" class="wallet-btn secondary">
          <i class="fas fa-cog"></i>
          Settings
        </nuxt-link>
        <nuxt-link to="/wallets/transactions" class="wallet-btn primary">
          <i class="fas fa-list"></i>
          All Transactions
        </nuxt-link>
        <nuxt-link to="/wallets/reports" class="wallet-btn secondary">
          <i class="fas fa-chart-bar"></i>
          Reports
        </nuxt-link>
        <nuxt-link to="/wallets/vouchers" class="wallet-btn secondary">
          <i class="fas fa-gift"></i>
          Vouchers
        </nuxt-link>
      </div>
    </div>

    <!-- Statistics Cards -->
    <div class="wallet-stats-grid">
      <div class="wallet-stat-card">
        <div class="stat-header">
          <div class="stat-icon info">
            <i class="fas fa-wallet"></i>
          </div>
        </div>
        <div class="stat-label">Total Balance</div>
        <div class="stat-value">฿{{ formatNumber(stats.totalBalance) }}</div>
        <div class="stat-subtitle">↑ {{ stats.balanceChange }}% from last month</div>
      </div>

      <div class="wallet-stat-card">
        <div class="stat-header">
          <div class="stat-icon success">
            <i class="fas fa-users"></i>
          </div>
        </div>
        <div class="stat-label">Active Wallets</div>
        <div class="stat-value">{{ formatNumber(stats.activeWallets) }}</div>
        <div class="stat-subtitle">{{ stats.newWallets }} new this week</div>
      </div>

      <div class="wallet-stat-card">
        <div class="stat-header">
          <div class="stat-icon info">
            <i class="fas fa-chart-line"></i>
          </div>
        </div>
        <div class="stat-label">Today's Volume</div>
        <div class="stat-value">฿{{ formatNumber(stats.todayVolume) }}</div>
        <div class="stat-subtitle">{{ stats.todayTransactions }} transactions</div>
      </div>

      <div class="wallet-stat-card">
        <div class="stat-header">
          <div class="stat-icon warning">
            <i class="fas fa-clock"></i>
          </div>
        </div>
        <div class="stat-label">Pending</div>
        <div class="stat-value">{{ stats.pendingCount }}</div>
        <div class="stat-subtitle">฿{{ formatNumber(stats.pendingAmount) }} total</div>
      </div>
    </div>

    <!-- Quick Filters -->
    <div class="wallet-filter-chips">
      <button
        @click="filters.status = ''; loadWallets()"
        :class="['wallet-filter-chip', { active: filters.status === '' }]"
      >
        <i class="fas fa-list"></i>
        All Wallets
      </button>
      <button
        @click="filters.status = 'active'; loadWallets()"
        :class="['wallet-filter-chip', { active: filters.status === 'active' }]"
      >
        <i class="fas fa-check-circle"></i>
        Active Only
      </button>
      <button
        @click="filters.status = 'frozen'; loadWallets()"
        :class="['wallet-filter-chip', { active: filters.status === 'frozen' }]"
      >
        <i class="fas fa-snowflake"></i>
        Frozen
      </button>
      <button
        @click="filters.status = 'suspended'; loadWallets()"
        :class="['wallet-filter-chip', { active: filters.status === 'suspended' }]"
      >
        <i class="fas fa-ban"></i>
        Suspended
      </button>
      <button @click="resetFilters" class="wallet-filter-chip">
        <i class="fas fa-redo"></i>
        Reset
      </button>
    </div>

    <!-- Advanced Filters -->
    <div class="wallet-filters-panel">
      <div class="wallet-filters-grid">
        <div class="wallet-filter-item">
          <label>
            <i class="fas fa-search"></i>
            Search
          </label>
          <input
            v-model="filters.search"
            type="text"
            placeholder="Name, email, phone, or user ID..."
            @input="debouncedSearch"
          />
        </div>

        <div class="wallet-filter-item">
          <label>
            <i class="fas fa-coins"></i>
            Min Balance
          </label>
          <input
            v-model="filters.minBalance"
            type="number"
            placeholder="0.00"
            @change="loadWallets"
          />
        </div>

        <div class="wallet-filter-item">
          <label>
            <i class="fas fa-coins"></i>
            Max Balance
          </label>
          <input
            v-model="filters.maxBalance"
            type="number"
            placeholder="1000000.00"
            @change="loadWallets"
          />
        </div>

        <div class="wallet-filter-item">
          <label>
            <i class="fas fa-sort"></i>
            Sort By
          </label>
          <select v-model="filters.sortBy" @change="loadWallets">
            <option value="created_at">Created Date</option>
            <option value="balance">Balance</option>
            <option value="last_transaction">Last Transaction</option>
          </select>
        </div>

        <div class="wallet-filter-item">
          <label>
            <i class="fas fa-sort-amount-down"></i>
            Order
          </label>
          <select v-model="filters.sortOrder" @change="loadWallets">
            <option value="desc">Newest First</option>
            <option value="asc">Oldest First</option>
          </select>
        </div>
      </div>
    </div>

    <!-- Wallets Table -->
    <div class="wallet-table-container">
      <table class="wallet-table">
        <thead>
          <tr>
            <th><i class="fas fa-hashtag"></i> User ID</th>
            <th><i class="fas fa-user"></i> Name</th>
            <th><i class="fas fa-envelope"></i> Email</th>
            <th><i class="fas fa-wallet"></i> Balance</th>
            <th><i class="fas fa-clock"></i> Pending</th>
            <th><i class="fas fa-info-circle"></i> Status</th>
            <th><i class="fas fa-calendar"></i> Last Transaction</th>
            <th><i class="fas fa-tools"></i> Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="8" class="wallet-loading">
              <i class="fas fa-spinner fa-spin"></i>
              <p>Loading wallets...</p>
            </td>
          </tr>
          <tr v-else-if="wallets.length === 0">
            <td colspan="8" class="wallet-empty">
              <i class="fas fa-inbox"></i>
              <p>No wallets found</p>
            </td>
          </tr>
          <tr v-else v-for="wallet in wallets" :key="wallet.userId">
            <td><strong>#{{ wallet.userId }}</strong></td>
            <td>{{ wallet.user.firstName }} {{ wallet.user.lastName }}</td>
            <td>{{ wallet.user.email }}</td>
            <td class="amount">฿{{ formatNumber(wallet.balance) }}</td>
            <td class="amount">฿{{ formatNumber(wallet.pendingBalance) }}</td>
            <td>
              <span :class="['wallet-status-badge', wallet.status]">
                <i v-if="wallet.status === 'active'" class="fas fa-check-circle"></i>
                <i v-else-if="wallet.status === 'frozen'" class="fas fa-snowflake"></i>
                <i v-else class="fas fa-ban"></i>
                {{ wallet.status }}
              </span>
            </td>
            <td>{{ formatDate(wallet.lastTransaction) }}</td>
            <td>
              <div class="actions">
                <nuxt-link :to="`/wallets/${wallet.userId}`" class="wallet-btn secondary" style="padding: 6px 12px; font-size: 12px;">
                  <i class="fas fa-eye"></i>
                  View
                </nuxt-link>
                <button @click="showAdjustModal(wallet)" class="wallet-btn secondary" style="padding: 6px 12px; font-size: 12px;">
                  <i class="fas fa-edit"></i>
                  Adjust
                </button>
                <button
                  v-if="wallet.status === 'active'"
                  @click="freezeWallet(wallet.userId)"
                  class="wallet-btn danger"
                  style="padding: 6px 12px; font-size: 12px;"
                >
                  <i class="fas fa-snowflake"></i>
                  Freeze
                </button>
                <button
                  v-else
                  @click="unfreezeWallet(wallet.userId)"
                  class="wallet-btn success"
                  style="padding: 6px 12px; font-size: 12px;"
                >
                  <i class="fas fa-check"></i>
                  Unfreeze
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Pagination -->
    <div style="display: flex; justify-content: center; align-items: center; gap: 20px; margin-top: 24px;">
      <button
        @click="prevPage"
        :disabled="pagination.offset === 0"
        class="wallet-btn secondary"
      >
        <i class="fas fa-chevron-left"></i>
        Previous
      </button>
      <span style="color: #6b7280; font-size: 14px;">
        Showing {{ pagination.offset + 1 }} -
        {{ Math.min(pagination.offset + pagination.limit, pagination.total) }}
        of {{ pagination.total }}
      </span>
      <button
        @click="nextPage"
        :disabled="!pagination.hasMore"
        class="wallet-btn secondary"
      >
        Next
        <i class="fas fa-chevron-right"></i>
      </button>
    </div>

    <!-- Adjust Balance Modal -->
    <div v-if="showAdjustDialog" class="modal-overlay" @click="closeAdjustModal">
      <div class="modal-content" @click.stop>
        <h2 style="font-size: 22px; color: #063F48; margin-bottom: 20px;">
          <i class="fas fa-balance-scale"></i>
          Adjust Wallet Balance
        </h2>
        <div class="modal-body">
          <div style="background: #F7FAFC; padding: 16px; border-radius: 12px; margin-bottom: 20px;">
            <p style="margin: 4px 0;"><strong>User:</strong> {{ adjustData.user?.firstName }} {{ adjustData.user?.lastName }}</p>
            <p style="margin: 4px 0;"><strong>Current Balance:</strong> <span style="color: #1797AD; font-weight: 600;">฿{{ formatNumber(adjustData.balance) }}</span></p>
          </div>

          <div class="wallet-filter-item" style="margin-bottom: 16px;">
            <label>Adjustment Type</label>
            <select v-model="adjustData.type">
              <option value="credit">Credit (Add Money)</option>
              <option value="debit">Debit (Deduct Money)</option>
            </select>
          </div>

          <div class="wallet-filter-item" style="margin-bottom: 16px;">
            <label>Amount (฿)</label>
            <input
              v-model="adjustData.amount"
              type="number"
              step="0.01"
              placeholder="Enter amount..."
            />
          </div>

          <div class="wallet-filter-item" style="margin-bottom: 20px;">
            <label>Reason (Required)</label>
            <textarea
              v-model="adjustData.reason"
              rows="3"
              placeholder="Enter reason for adjustment..."
              style="width: 100%; padding: 10px 14px; border: 2px solid #E2E8F0; border-radius: 12px; font-size: 14px; font-family: inherit; resize: vertical;"
            ></textarea>
          </div>

          <div style="display: flex; justify-content: flex-end; gap: 12px;">
            <button @click="closeAdjustModal" class="wallet-btn secondary">
              <i class="fas fa-times"></i>
              Cancel
            </button>
            <button @click="submitAdjustment" class="wallet-btn success" :disabled="!canSubmitAdjustment">
              <i class="fas fa-check"></i>
              Adjust Balance
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Breadcrumb from '~/components/Breadcrumb';

export default {
  name: 'WalletsIndex',
  middleware: 'auth',
  components: {
    Breadcrumb,
  },
  data() {
    return {
      breadcrumbs: [
        { label: 'Dashboard', path: '/dashboard' },
        { label: 'Wallet Management' },
      ],
      wallets: [],
      loading: false,
      filters: {
        search: '',
        status: '',
        minBalance: '',
        maxBalance: '',
        sortBy: 'created_at',
        sortOrder: 'desc',
      },
      pagination: {
        limit: 50,
        offset: 0,
        total: 0,
        hasMore: false,
      },
      stats: {
        totalBalance: 0,
        activeWallets: 0,
        balanceChange: 0,
        newWallets: 0,
        todayVolume: 0,
        todayTransactions: 0,
        pendingCount: 0,
        pendingAmount: 0,
      },
      showAdjustDialog: false,
      adjustData: {
        userId: null,
        user: null,
        balance: 0,
        type: 'credit',
        amount: '',
        reason: '',
      },
      searchTimeout: null,
    };
  },
  computed: {
    canSubmitAdjustment() {
      return (
        this.adjustData.amount &&
        parseFloat(this.adjustData.amount) > 0 &&
        this.adjustData.reason.trim().length > 0
      );
    },
  },
  async mounted() {
    await this.loadWallets();
    await this.loadStats();
  },
  methods: {
    async loadWallets() {
      this.loading = true;
      try {
        const params = {
          limit: this.pagination.limit,
          offset: this.pagination.offset,
          ...this.filters,
        };

        const response = await this.$walletService.getWallets(params);

        if (response.success) {
          this.wallets = response.data.wallets;
          this.pagination = response.data.pagination;
        }
      } catch (error) {
        console.error('Error loading wallets:', error);
        this.$swal({
          icon: 'error',
          title: 'Error',
          text: 'Failed to load wallets',
        });
      } finally {
        this.loading = false;
      }
    },

    async loadStats() {
      try {
        const response = await this.$walletService.getReports({
          reportType: 'summary',
        });

        if (response.success) {
          const data = response.data;
          this.stats = {
            totalBalance: data.summary?.totalWalletBalance || 0,
            activeWallets: data.summary?.activeWallets || 0,
            balanceChange: 12.5,
            newWallets: 234,
            todayVolume: data.transactionSummary?.totalVolume || 0,
            todayTransactions: data.transactionSummary?.totalTransactions || 0,
            pendingCount: 24,
            pendingAmount: 8450,
          };
        }
      } catch (error) {
        console.error('Error loading stats:', error);
      }
    },

    debouncedSearch() {
      clearTimeout(this.searchTimeout);
      this.searchTimeout = setTimeout(() => {
        this.pagination.offset = 0;
        this.loadWallets();
      }, 500);
    },

    resetFilters() {
      this.filters = {
        search: '',
        status: '',
        minBalance: '',
        maxBalance: '',
        sortBy: 'created_at',
        sortOrder: 'desc',
      };
      this.pagination.offset = 0;
      this.loadWallets();
    },

    prevPage() {
      if (this.pagination.offset > 0) {
        this.pagination.offset -= this.pagination.limit;
        this.loadWallets();
      }
    },

    nextPage() {
      if (this.pagination.hasMore) {
        this.pagination.offset += this.pagination.limit;
        this.loadWallets();
      }
    },

    showAdjustModal(wallet) {
      this.adjustData = {
        userId: wallet.userId,
        user: wallet.user,
        balance: wallet.balance,
        type: 'credit',
        amount: '',
        reason: '',
      };
      this.showAdjustDialog = true;
    },

    closeAdjustModal() {
      this.showAdjustDialog = false;
      this.adjustData = {
        userId: null,
        user: null,
        balance: 0,
        type: 'credit',
        amount: '',
        reason: '',
      };
    },

    async submitAdjustment() {
      try {
        const response = await this.$walletService.adjustBalance({
          userId: this.adjustData.userId,
          amount: parseFloat(this.adjustData.amount),
          type: this.adjustData.type,
          reason: this.adjustData.reason,
        });

        if (response.success) {
          this.$swal({
            icon: 'success',
            title: 'Success',
            text: 'Wallet balance adjusted successfully',
          });
          this.closeAdjustModal();
          this.loadWallets();
        }
      } catch (error) {
        console.error('Error adjusting balance:', error);
        this.$swal({
          icon: 'error',
          title: 'Error',
          text: error.response?.data?.error?.message || 'Failed to adjust balance',
        });
      }
    },

    async freezeWallet(userId) {
      const result = await this.$swal({
        icon: 'warning',
        title: 'Freeze Wallet?',
        text: 'Enter reason for freezing this wallet:',
        input: 'textarea',
        inputPlaceholder: 'Reason for freezing...',
        showCancelButton: true,
        confirmButtonText: 'Freeze',
        inputValidator: (value) => {
          if (!value) {
            return 'Reason is required';
          }
        },
      });

      if (result.isConfirmed) {
        try {
          const response = await this.$walletService.freezeWallet({
            userId,
            action: 'freeze',
            reason: result.value,
          });

          if (response.success) {
            this.$swal({
              icon: 'success',
              title: 'Success',
              text: 'Wallet frozen successfully',
            });
            this.loadWallets();
          }
        } catch (error) {
          console.error('Error freezing wallet:', error);
          this.$swal({
            icon: 'error',
            title: 'Error',
            text: 'Failed to freeze wallet',
          });
        }
      }
    },

    async unfreezeWallet(userId) {
      const result = await this.$swal({
        icon: 'question',
        title: 'Unfreeze Wallet?',
        text: 'Are you sure you want to unfreeze this wallet?',
        showCancelButton: true,
        confirmButtonText: 'Unfreeze',
      });

      if (result.isConfirmed) {
        try {
          const response = await this.$walletService.freezeWallet({
            userId,
            action: 'unfreeze',
          });

          if (response.success) {
            this.$swal({
              icon: 'success',
              title: 'Success',
              text: 'Wallet unfrozen successfully',
            });
            this.loadWallets();
          }
        } catch (error) {
          console.error('Error unfreezing wallet:', error);
          this.$swal({
            icon: 'error',
            title: 'Error',
            text: 'Failed to unfreeze wallet',
          });
        }
      }
    },

    async exportData() {
      try {
        const csvData = await this.$walletService.exportWallets(this.filters);
        const filename = `wallets-${new Date().toISOString().split('T')[0]}.csv`;
        this.$walletService.downloadCSV(csvData, filename);
      } catch (error) {
        console.error('Error exporting data:', error);
        this.$swal({
          icon: 'error',
          title: 'Error',
          text: 'Failed to export data',
        });
      }
    },

    formatNumber(value) {
      if (value === null || value === undefined) return '0.00';
      return parseFloat(value).toLocaleString('en-US', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      });
    },

    formatDate(date) {
      if (!date) return 'Never';
      return this.$moment(date).tz('Asia/Bangkok').format('MMM D, YYYY HH:mm');
    },
  },
};
</script>

<style scoped>
.actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 16px;
  padding: 32px;
  max-width: 600px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.modal-body {
  margin-top: 0;
}
</style>
