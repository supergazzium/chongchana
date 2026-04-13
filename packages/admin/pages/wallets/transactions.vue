<template>
  <div class="transactions-page">
    <Breadcrumb :items="breadcrumbs" />

    <!-- Page Header with Actions -->
    <div class="page-header">
      <div class="header-left">
        <h1>Transactions</h1>
        <span class="total-count">{{ pagination.total }} total</span>
      </div>
      <div class="header-actions">
        <button @click="toggleFilters" class="btn-secondary">
          <i class="fas fa-filter"></i>
          Filters
          <span v-if="activeFiltersCount" class="badge">{{ activeFiltersCount }}</span>
        </button>
        <button @click="exportData" class="btn-primary">
          <i class="fas fa-download"></i>
          Export
        </button>
      </div>
    </div>

    <!-- Summary Cards -->
    <div class="summary-grid">
      <div class="summary-card">
        <div class="card-icon completed">
          <i class="fas fa-check-circle"></i>
        </div>
        <div class="card-content">
          <div class="card-value">{{ summary.completed }}</div>
          <div class="card-label">Completed</div>
        </div>
      </div>

      <div class="summary-card">
        <div class="card-icon pending">
          <i class="fas fa-clock"></i>
        </div>
        <div class="card-content">
          <div class="card-value">{{ summary.pending }}</div>
          <div class="card-label">Pending</div>
        </div>
      </div>

      <div class="summary-card">
        <div class="card-icon failed">
          <i class="fas fa-times-circle"></i>
        </div>
        <div class="card-content">
          <div class="card-value">{{ summary.failed }}</div>
          <div class="card-label">Failed</div>
        </div>
      </div>

      <div class="summary-card">
        <div class="card-icon volume">
          <i class="fas fa-coins"></i>
        </div>
        <div class="card-content">
          <div class="card-value">฿{{ formatNumber(summary.totalVolume) }}</div>
          <div class="card-label">Total Volume</div>
        </div>
      </div>
    </div>

    <!-- Quick Filters (Chips) -->
    <div class="quick-filters">
      <button
        v-for="filter in quickFilters"
        :key="filter.value"
        @click="applyQuickFilter(filter.value)"
        :class="['filter-chip', { active: filters.type === filter.value }]"
      >
        <i :class="filter.icon"></i>
        {{ filter.label }}
      </button>
    </div>

    <!-- Advanced Filters (Collapsible) -->
    <transition name="slide-down">
      <div v-if="showFilters" class="advanced-filters">
        <div class="filters-grid">
          <div class="filter-item">
            <label>Search</label>
            <input
              v-model="filters.search"
              type="text"
              placeholder="Transaction ID, user..."
              class="filter-input"
              @input="debouncedSearch"
            >
          </div>

          <div class="filter-item">
            <label>Status</label>
            <select v-model="filters.status" @change="loadTransactions" class="filter-select">
              <option value="">All Status</option>
              <option value="completed">Completed</option>
              <option value="pending">Pending</option>
              <option value="failed">Failed</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </div>

          <div class="filter-item">
            <label>Branch</label>
            <input
              v-model="filters.branch"
              type="text"
              placeholder="Branch name"
              class="filter-input"
              @change="loadTransactions"
            >
          </div>

          <div class="filter-item">
            <label>Amount Range</label>
            <div class="amount-range">
              <input
                v-model="filters.minAmount"
                type="number"
                placeholder="Min"
                class="filter-input-small"
                @change="loadTransactions"
              >
              <span>–</span>
              <input
                v-model="filters.maxAmount"
                type="number"
                placeholder="Max"
                class="filter-input-small"
                @change="loadTransactions"
              >
            </div>
          </div>

          <div class="filter-item">
            <label>Staff ID</label>
            <input
              v-model="filters.staffId"
              type="text"
              placeholder="Staff ID"
              class="filter-input"
              @change="loadTransactions"
            >
          </div>

          <div class="filter-item">
            <label>Machine ID</label>
            <input
              v-model="filters.machineId"
              type="text"
              placeholder="Machine ID"
              class="filter-input"
              @change="loadTransactions"
            >
          </div>
        </div>

        <div class="filter-actions">
          <button @click="resetFilters" class="btn-text">
            <i class="fas fa-redo"></i>
            Reset All
          </button>
          <button @click="showFilters = false" class="btn-secondary">
            Apply Filters
          </button>
        </div>
      </div>
    </transition>

    <!-- Transactions Table (Redesigned) -->
    <div class="table-wrapper">
      <div v-if="loading" class="loading-overlay">
        <div class="spinner"></div>
        <p>Loading transactions...</p>
      </div>

      <table v-else class="transactions-table-new">
        <thead>
          <tr>
            <th>Transaction</th>
            <th>User</th>
            <th class="th-center">Status</th>
            <th class="th-center">Type</th>
            <th>Branch</th>
            <th class="th-right">Amount</th>
            <th class="th-center">Date</th>
            <th class="th-actions">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="transactions.length === 0">
            <td colspan="8" class="empty-state">
              <i class="fas fa-inbox"></i>
              <p>No transactions found</p>
              <button @click="resetFilters" class="btn-text">Clear filters</button>
            </td>
          </tr>

          <tr
            v-else
            v-for="transaction in transactions"
            :key="transaction.id"
            class="transaction-row"
            @click="showTransactionDetail(transaction)"
          >
            <td class="td-transaction">
              <div class="transaction-id">#{{ transaction.id }}</div>
              <div class="transaction-description">{{ transaction.description }}</div>
            </td>

            <td class="td-user">
              <div class="user-info">
                <div class="user-avatar">
                  {{ getInitials(transaction.user.firstName, transaction.user.lastName) }}
                </div>
                <div class="user-details">
                  <div class="user-name">
                    {{ transaction.user.firstName }} {{ transaction.user.lastName }}
                  </div>
                  <div class="user-email">{{ transaction.user.email }}</div>
                </div>
              </div>
            </td>

            <td class="td-center">
              <span :class="['status-badge', 'status-' + transaction.status]">
                <i :class="getStatusIcon(transaction.status)"></i>
                {{ transaction.status }}
              </span>
            </td>

            <td class="td-center">
              <span :class="['type-badge', 'type-' + transaction.type]">
                {{ formatType(transaction.type) }}
              </span>
            </td>

            <td class="td-branch">
              <span v-if="transaction.branch" class="branch-tag">
                <i class="fas fa-map-marker-alt"></i>
                {{ transaction.branch }}
              </span>
              <span v-else class="text-muted">–</span>
            </td>

            <td class="td-right">
              <div :class="['amount', getAmountClass(transaction.type)]">
                {{ getAmountPrefix(transaction.type) }}฿{{ formatNumber(transaction.amount) }}
              </div>
            </td>

            <td class="td-center">
              <div class="date-info">
                <div class="date">{{ formatDate(transaction.createdAt) }}</div>
                <div class="time">{{ formatTime(transaction.createdAt) }}</div>
              </div>
            </td>

            <td class="td-actions" @click.stop>
              <button @click="showTransactionDetail(transaction)" class="btn-icon" title="View Details">
                <i class="fas fa-eye"></i>
              </button>
              <button
                v-if="canRefund(transaction)"
                @click="refundTransaction(transaction)"
                class="btn-icon btn-danger"
                title="Refund"
              >
                <i class="fas fa-undo"></i>
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Pagination (Redesigned) -->
    <div class="pagination-wrapper">
      <div class="pagination-info">
        Showing {{ pagination.offset + 1 }} - {{ Math.min(pagination.offset + pagination.limit, pagination.total) }}
        of {{ pagination.total }} transactions
      </div>

      <div class="pagination-controls">
        <button
          @click="prevPage"
          :disabled="pagination.offset === 0"
          class="pagination-btn"
        >
          <i class="fas fa-chevron-left"></i>
        </button>

        <div class="pagination-pages">
          <button
            v-for="page in paginationPages"
            :key="page"
            @click="goToPage(page)"
            :class="['pagination-page', { active: currentPage === page }]"
          >
            {{ page }}
          </button>
        </div>

        <button
          @click="nextPage"
          :disabled="!pagination.hasMore"
          class="pagination-btn"
        >
          <i class="fas fa-chevron-right"></i>
        </button>
      </div>

      <div class="pagination-size">
        <select v-model="pagination.limit" @change="changePageSize" class="page-size-select">
          <option :value="25">25 per page</option>
          <option :value="50">50 per page</option>
          <option :value="100">100 per page</option>
        </select>
      </div>
    </div>

    <!-- Transaction Detail Sidebar (Instead of Modal) -->
    <transition name="slide-right">
      <div v-if="selectedTransaction" class="detail-sidebar">
        <div class="sidebar-header">
          <h3>Transaction Details</h3>
          <button @click="closeDetailSidebar" class="btn-close">
            <i class="fas fa-times"></i>
          </button>
        </div>

        <div class="sidebar-content">
          <div class="detail-section">
            <div class="section-header">
              <h4>Overview</h4>
              <span :class="['status-badge', 'status-' + selectedTransaction.status]">
                {{ selectedTransaction.status }}
              </span>
            </div>

            <div class="detail-grid">
              <div class="detail-item full-width">
                <label>Transaction ID</label>
                <div class="value mono">#{{ selectedTransaction.id }}</div>
              </div>

              <div class="detail-item full-width">
                <label>Amount</label>
                <div :class="['value', 'amount-large', getAmountClass(selectedTransaction.type)]">
                  {{ getAmountPrefix(selectedTransaction.type) }}฿{{ formatNumber(selectedTransaction.amount) }}
                </div>
              </div>

              <div class="detail-item">
                <label>Type</label>
                <div class="value">
                  <span :class="['type-badge', 'type-' + selectedTransaction.type]">
                    {{ formatType(selectedTransaction.type) }}
                  </span>
                </div>
              </div>

              <div class="detail-item">
                <label>Date & Time</label>
                <div class="value">{{ formatDateTime(selectedTransaction.createdAt) }}</div>
              </div>
            </div>
          </div>

          <div class="detail-section">
            <h4>Customer Information</h4>
            <div class="detail-grid">
              <div class="detail-item full-width">
                <label>Name</label>
                <div class="value">
                  {{ selectedTransaction.user.firstName }} {{ selectedTransaction.user.lastName }}
                </div>
              </div>

              <div class="detail-item full-width">
                <label>Email</label>
                <div class="value">{{ selectedTransaction.user.email }}</div>
              </div>

              <div class="detail-item">
                <label>Balance Before</label>
                <div class="value">฿{{ formatNumber(selectedTransaction.balanceBefore) }}</div>
              </div>

              <div class="detail-item">
                <label>Balance After</label>
                <div class="value">฿{{ formatNumber(selectedTransaction.balanceAfter) }}</div>
              </div>
            </div>
          </div>

          <div v-if="selectedTransaction.branch" class="detail-section">
            <h4>Location</h4>
            <div class="detail-item">
              <label>Branch</label>
              <div class="value">
                <span class="branch-tag">
                  <i class="fas fa-map-marker-alt"></i>
                  {{ selectedTransaction.branch }}
                </span>
              </div>
            </div>
          </div>

          <div v-if="selectedTransaction.processedBy" class="detail-section">
            <h4>Processed By</h4>
            <div class="detail-item">
              <label>Staff Member</label>
              <div class="value">{{ selectedTransaction.processedBy.staff?.name || 'Unknown' }}</div>
            </div>
          </div>

          <div v-if="selectedTransaction.description" class="detail-section">
            <h4>Description</h4>
            <p class="description-text">{{ selectedTransaction.description }}</p>
          </div>

          <div v-if="selectedTransaction.paymentMethod" class="detail-section">
            <h4>Payment Details</h4>
            <div class="detail-grid">
              <div class="detail-item">
                <label>Payment Method</label>
                <div class="value">{{ selectedTransaction.paymentMethod }}</div>
              </div>
              <div v-if="selectedTransaction.paymentTransactionId" class="detail-item">
                <label>Transaction ID</label>
                <div class="value mono">{{ selectedTransaction.paymentTransactionId }}</div>
              </div>
            </div>
          </div>
        </div>

        <div class="sidebar-footer">
          <button
            v-if="canRefund(selectedTransaction)"
            @click="refundTransaction(selectedTransaction)"
            class="btn-danger"
          >
            <i class="fas fa-undo"></i>
            Process Refund
          </button>
          <button @click="closeDetailSidebar" class="btn-secondary">
            Close
          </button>
        </div>
      </div>
    </transition>

    <!-- Overlay for sidebar -->
    <div
      v-if="selectedTransaction"
      class="detail-overlay"
      @click="closeDetailSidebar"
    ></div>
  </div>
</template>

<script>
import Breadcrumb from '~/components/Breadcrumb';

export default {
  name: 'TransactionsRedesign',
  middleware: 'auth',
  components: { Breadcrumb },

  data() {
    return {
      breadcrumbs: [
        { label: 'Dashboard', path: '/dashboard' },
        { label: 'Wallet Management', path: '/wallets' },
        { label: 'Transactions' },
      ],
      transactions: [],
      loading: false,
      showFilters: false,
      selectedTransaction: null,

      filters: {
        search: '',
        type: '',
        status: '',
        branch: '',
        staffId: '',
        machineId: '',
        minAmount: '',
        maxAmount: '',
      },

      pagination: {
        limit: 50,
        offset: 0,
        total: 0,
        hasMore: false,
      },

      summary: {
        completed: 0,
        pending: 0,
        failed: 0,
        totalVolume: 0,
      },

      quickFilters: [
        { value: '', label: 'All', icon: 'fas fa-list' },
        { value: 'top_up', label: 'Top Ups', icon: 'fas fa-arrow-up' },
        { value: 'store_payment', label: 'Payments', icon: 'fas fa-shopping-cart' },
        { value: 'refund', label: 'Refunds', icon: 'fas fa-undo' },
      ],

      searchTimeout: null,
    };
  },

  computed: {
    currentPage() {
      return Math.floor(this.pagination.offset / this.pagination.limit) + 1;
    },

    totalPages() {
      return Math.ceil(this.pagination.total / this.pagination.limit);
    },

    paginationPages() {
      const pages = [];
      const current = this.currentPage;
      const total = this.totalPages;

      // Show max 7 pages
      let start = Math.max(1, current - 3);
      let end = Math.min(total, current + 3);

      if (end - start < 6) {
        if (start === 1) {
          end = Math.min(total, start + 6);
        } else {
          start = Math.max(1, end - 6);
        }
      }

      for (let i = start; i <= end; i++) {
        pages.push(i);
      }

      return pages;
    },

    activeFiltersCount() {
      let count = 0;
      Object.entries(this.filters).forEach(([key, value]) => {
        if (value && key !== 'search') count++;
      });
      return count;
    },
  },

  async mounted() {
    await Promise.all([
      this.loadTransactions(),
      this.loadSummary(),
    ]);
  },

  methods: {
    async loadTransactions() {
      this.loading = true;
      try {
        const params = {
          limit: this.pagination.limit,
          offset: this.pagination.offset,
          ...this.filters,
        };

        const response = await this.$walletService.getTransactions(params);

        if (response.success) {
          this.transactions = response.data.transactions;
          this.pagination = response.data.pagination;
        }
      } catch (error) {
        console.error('Error loading transactions:', error);
        this.$swal({
          icon: 'error',
          title: 'Error',
          text: 'Failed to load transactions',
        });
      } finally {
        this.loading = false;
      }
    },

    async loadSummary() {
      // Calculate from current data - you can implement API call if needed
      const completed = this.transactions.filter(t => t.status === 'completed').length;
      const pending = this.transactions.filter(t => t.status === 'pending').length;
      const failed = this.transactions.filter(t => t.status === 'failed').length;
      const totalVolume = this.transactions
        .filter(t => t.status === 'completed')
        .reduce((sum, t) => sum + Math.abs(parseFloat(t.amount) || 0), 0);

      this.summary = { completed, pending, failed, totalVolume };
    },

    toggleFilters() {
      this.showFilters = !this.showFilters;
    },

    applyQuickFilter(type) {
      this.filters.type = type;
      this.pagination.offset = 0;
      this.loadTransactions();
    },

    debouncedSearch() {
      clearTimeout(this.searchTimeout);
      this.searchTimeout = setTimeout(() => {
        this.pagination.offset = 0;
        this.loadTransactions();
      }, 500);
    },

    resetFilters() {
      this.filters = {
        search: '',
        type: '',
        status: '',
        branch: '',
        staffId: '',
        machineId: '',
        minAmount: '',
        maxAmount: '',
      };
      this.pagination.offset = 0;
      this.loadTransactions();
    },

    prevPage() {
      if (this.pagination.offset > 0) {
        this.pagination.offset -= this.pagination.limit;
        this.loadTransactions();
        window.scrollTo({ top: 0, behavior: 'smooth' });
      }
    },

    nextPage() {
      if (this.pagination.hasMore) {
        this.pagination.offset += this.pagination.limit;
        this.loadTransactions();
        window.scrollTo({ top: 0, behavior: 'smooth' });
      }
    },

    goToPage(page) {
      this.pagination.offset = (page - 1) * this.pagination.limit;
      this.loadTransactions();
      window.scrollTo({ top: 0, behavior: 'smooth' });
    },

    changePageSize() {
      this.pagination.offset = 0;
      this.loadTransactions();
    },

    showTransactionDetail(transaction) {
      this.selectedTransaction = transaction;
    },

    closeDetailSidebar() {
      this.selectedTransaction = null;
    },

    canRefund(transaction) {
      return transaction.type === 'payment' && transaction.status === 'completed';
    },

    async refundTransaction(transaction) {
      const result = await this.$swal({
        icon: 'warning',
        title: 'Refund Transaction?',
        html: `
          <p>Are you sure you want to refund this transaction?</p>
          <p><strong>Amount:</strong> ฿${this.formatNumber(transaction.amount)}</p>
        `,
        input: 'textarea',
        inputLabel: 'Reason for refund (required)',
        inputPlaceholder: 'Enter reason for refund...',
        showCancelButton: true,
        confirmButtonText: 'Process Refund',
        confirmButtonColor: '#dc2626',
        inputValidator: (value) => {
          if (!value) return 'Reason is required';
        },
      });

      if (result.isConfirmed) {
        try {
          const response = await this.$walletService.refundTransaction({
            transactionId: transaction.id,
            refundType: 'full',
            reason: result.value,
          });

          if (response.success) {
            this.$swal({
              icon: 'success',
              title: 'Success',
              text: 'Transaction refunded successfully',
            });
            this.loadTransactions();
            this.closeDetailSidebar();
          }
        } catch (error) {
          console.error('Error refunding transaction:', error);
          this.$swal({
            icon: 'error',
            title: 'Error',
            text: error.response?.data?.error?.message || 'Failed to refund transaction',
          });
        }
      }
    },

    async exportData() {
      try {
        const csvData = await this.$walletService.exportTransactions(this.filters);
        const filename = `transactions-${new Date().toISOString().split('T')[0]}.csv`;
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

    // Helper methods
    getInitials(firstName, lastName) {
      return `${firstName?.charAt(0) || ''}${lastName?.charAt(0) || ''}`.toUpperCase();
    },

    getStatusIcon(status) {
      const icons = {
        completed: 'fas fa-check-circle',
        pending: 'fas fa-clock',
        failed: 'fas fa-times-circle',
        cancelled: 'fas fa-ban',
      };
      return icons[status] || 'fas fa-circle';
    },

    formatType(type) {
      const types = {
        top_up: 'Top Up',
        payment: 'Payment',
        store_payment: 'Store Payment',
        beer_machine_payment: 'Beer Machine',
        refund: 'Refund',
        bonus: 'Bonus',
        adjustment: 'Adjustment',
        withdrawal: 'Withdrawal',
      };
      return types[type] || type;
    },

    getAmountClass(type) {
      const creditTypes = ['top_up', 'refund', 'bonus'];
      return creditTypes.includes(type) ? 'positive' : 'negative';
    },

    getAmountPrefix(type) {
      const creditTypes = ['top_up', 'refund', 'bonus'];
      return creditTypes.includes(type) ? '+' : '-';
    },

    formatNumber(value) {
      if (value === null || value === undefined) return '0.00';
      return Math.abs(parseFloat(value)).toLocaleString('en-US', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      });
    },

    formatDate(date) {
      if (!date) return 'N/A';
      return this.$moment(date).tz('Asia/Bangkok').format('MMM D, YYYY');
    },

    formatTime(date) {
      if (!date) return '';
      return this.$moment(date).tz('Asia/Bangkok').format('HH:mm');
    },

    formatDateTime(date) {
      if (!date) return 'N/A';
      return this.$moment(date).tz('Asia/Bangkok').format('MMM D, YYYY [at] HH:mm');
    },
  },
};
</script>

<style scoped>
/* Wallet Design System Variables - Teal Theme */
:root {
  --primary: #1797AD;
  --primary-dark: #14828E;
  --primary-light: #1BA4BC;
  --dark-green: #063F48;
  --success: #00A862;
  --warning: #FFB800;
  --danger: #D32F2F;
  --gray-50: #F7FAFC;
  --gray-100: #F7F5F2;
  --gray-200: #E2E8F0;
  --gray-300: #D1D5DB;
  --gray-400: #9CA3AF;
  --gray-500: #6B7280;
  --gray-600: #4B5563;
  --gray-700: #4A5568;
  --gray-800: #2D3748;
  --gray-900: #063F48;
  --radius: 12px;
  --radius-lg: 16px;
  --shadow-sm: 0 2px 8px rgba(0, 0, 0, 0.04);
  --shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
  --shadow-md: 0 4px 16px rgba(23, 151, 173, 0.12);
  --shadow-lg: 0 8px 24px rgba(23, 151, 173, 0.15);
}

/* Page Layout */
.transactions-page {
  padding: 24px;
  max-width: 1600px;
  margin: 0 auto;
  background: #F7F5F2;
  min-height: 100vh;
}

/* Page Header */
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.header-left {
  display: flex;
  align-items: baseline;
  gap: 12px;
}

.page-header h1 {
  font-size: 28px;
  font-weight: 700;
  color: var(--gray-900);
  margin: 0;
}

.total-count {
  font-size: 14px;
  color: var(--gray-500);
  font-weight: 500;
}

.header-actions {
  display: flex;
  gap: 12px;
}

/* Buttons */
.btn-primary,
.btn-secondary,
.btn-text,
.btn-danger {
  padding: 10px 20px;
  border-radius: var(--radius);
  font-size: 14px;
  font-weight: 600;
  border: none;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s;
}

.btn-primary {
  background: var(--primary);
  color: white;
}

.btn-primary:hover {
  background: var(--primary-dark);
  transform: translateY(-1px);
  box-shadow: var(--shadow-md);
}

.btn-secondary {
  background: white;
  color: var(--gray-700);
  border: 1px solid var(--gray-300);
  position: relative;
}

.btn-secondary:hover {
  background: var(--gray-50);
}

.btn-secondary .badge {
  position: absolute;
  top: -8px;
  right: -8px;
  background: var(--danger);
  color: white;
  font-size: 11px;
  font-weight: 700;
  padding: 2px 6px;
  border-radius: 10px;
  min-width: 18px;
  text-align: center;
}

.btn-text {
  background: transparent;
  color: var(--primary);
  padding: 8px 12px;
}

.btn-text:hover {
  background: var(--gray-100);
}

.btn-danger {
  background: var(--danger);
  color: white;
}

.btn-danger:hover {
  background: #dc2626;
}

.btn-icon {
  width: 36px;
  height: 36px;
  border-radius: var(--radius);
  border: none;
  background: var(--gray-100);
  color: var(--gray-600);
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.btn-icon:hover {
  background: var(--gray-200);
  color: var(--gray-900);
}

.btn-icon.btn-danger {
  background: #fee2e2;
  color: var(--danger);
}

.btn-icon.btn-danger:hover {
  background: #fecaca;
}

/* Summary Cards */
.summary-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 24px;
}

.summary-card {
  background: white;
  border-radius: var(--radius-lg);
  padding: 24px;
  display: flex;
  align-items: center;
  gap: 16px;
  box-shadow: var(--shadow);
  transition: transform 0.2s, box-shadow 0.2s;
}

.summary-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

.card-icon {
  width: 56px;
  height: 56px;
  border-radius: var(--radius-lg);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
}

.card-icon.completed {
  background: #d1fae5;
  color: var(--success);
}

.card-icon.pending {
  background: #fef3c7;
  color: var(--warning);
}

.card-icon.failed {
  background: #fee2e2;
  color: var(--danger);
}

.card-icon.volume {
  background: #dbeafe;
  color: var(--primary);
}

.card-content {
  flex: 1;
}

.card-value {
  font-size: 32px;
  font-weight: 700;
  color: var(--gray-900);
  line-height: 1;
  margin-bottom: 4px;
}

.card-label {
  font-size: 14px;
  color: var(--gray-500);
  font-weight: 500;
}

/* Quick Filters */
.quick-filters {
  display: flex;
  gap: 12px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.filter-chip {
  padding: 10px 20px;
  border-radius: 20px;
  background: white;
  border: 2px solid var(--gray-200);
  color: var(--gray-700);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s;
}

.filter-chip:hover {
  border-color: var(--primary);
  background: #eff6ff;
}

.filter-chip.active {
  background: var(--primary);
  color: white;
  border-color: var(--primary);
}

/* Advanced Filters */
.advanced-filters {
  background: white;
  border-radius: var(--radius-lg);
  padding: 24px;
  margin-bottom: 20px;
  box-shadow: var(--shadow);
}

.filters-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-bottom: 20px;
}

.filter-item label {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: var(--gray-700);
  margin-bottom: 8px;
}

.filter-input,
.filter-select {
  width: 100%;
  padding: 10px 14px;
  border: 1px solid var(--gray-300);
  border-radius: var(--radius);
  font-size: 14px;
  color: var(--gray-900);
  transition: all 0.2s;
}

.filter-input:focus,
.filter-select:focus {
  outline: none;
  border-color: var(--primary);
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.amount-range {
  display: flex;
  align-items: center;
  gap: 8px;
}

.filter-input-small {
  flex: 1;
  padding: 10px 14px;
  border: 1px solid var(--gray-300);
  border-radius: var(--radius);
  font-size: 14px;
}

.filter-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 16px;
  border-top: 1px solid var(--gray-200);
}

/* Transitions */
.slide-down-enter-active,
.slide-down-leave-active {
  transition: all 0.3s ease;
  max-height: 500px;
  overflow: hidden;
}

.slide-down-enter-from,
.slide-down-leave-to {
  max-height: 0;
  opacity: 0;
}

/* Table */
.table-wrapper {
  background: white;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow);
  overflow: hidden;
  position: relative;
  min-height: 400px;
}

.loading-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(255, 255, 255, 0.95);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
  z-index: 10;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid var(--gray-200);
  border-top-color: var(--primary);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.transactions-table-new {
  width: 100%;
  border-collapse: collapse;
}

.transactions-table-new thead {
  background: var(--gray-50);
  border-bottom: 2px solid var(--gray-200);
}

.transactions-table-new th {
  padding: 16px;
  text-align: left;
  font-size: 12px;
  font-weight: 700;
  color: var(--gray-600);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.th-center { text-align: center; }
.th-right { text-align: right; }
.th-actions { width: 100px; text-align: center; }

.transactions-table-new tbody tr {
  border-bottom: 1px solid var(--gray-100);
  transition: background 0.2s;
  cursor: pointer;
}

.transactions-table-new tbody tr:hover {
  background: var(--gray-50);
}

.transactions-table-new td {
  padding: 16px;
  font-size: 14px;
  color: var(--gray-900);
  vertical-align: middle;
}

.td-center { text-align: center; }
.td-right { text-align: right; }

/* Transaction Cells */
.td-transaction {
  max-width: 200px;
}

.transaction-id {
  font-family: monospace;
  font-size: 13px;
  color: var(--gray-900);
  font-weight: 600;
  margin-bottom: 4px;
}

.transaction-description {
  font-size: 13px;
  color: var(--gray-500);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* User Info */
.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--primary), #8b5cf6);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 14px;
  flex-shrink: 0;
}

.user-details {
  flex: 1;
  min-width: 0;
}

.user-name {
  font-weight: 600;
  color: var(--gray-900);
  margin-bottom: 2px;
}

.user-email {
  font-size: 13px;
  color: var(--gray-500);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Status Badge */
.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
  text-transform: capitalize;
}

.status-completed {
  background: #d1fae5;
  color: #065f46;
}

.status-pending {
  background: #fef3c7;
  color: #92400e;
}

.status-failed {
  background: #fee2e2;
  color: #991b1b;
}

.status-cancelled {
  background: var(--gray-200);
  color: var(--gray-700);
}

/* Type Badge */
.type-badge {
  display: inline-block;
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
}

.type-top_up {
  background: #dbeafe;
  color: #1e40af;
}

.type-payment,
.type-store_payment {
  background: #fef3c7;
  color: #92400e;
}

.type-beer_machine_payment {
  background: #fef3c7;
  color: #92400e;
}

.type-refund {
  background: #d1fae5;
  color: #065f46;
}

.type-bonus {
  background: #e0e7ff;
  color: #3730a3;
}

/* Branch Tag */
.branch-tag {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  background: var(--gray-100);
  border-radius: 6px;
  font-size: 13px;
  color: var(--gray-700);
}

/* Amount */
.amount {
  font-family: monospace;
  font-size: 15px;
  font-weight: 700;
}

.amount.positive {
  color: var(--success);
}

.amount.negative {
  color: var(--danger);
}

/* Date Info */
.date-info {
  text-align: center;
}

.date {
  font-size: 14px;
  font-weight: 600;
  color: var(--gray-900);
  margin-bottom: 2px;
}

.time {
  font-size: 12px;
  color: var(--gray-500);
}

/* Actions */
.td-actions {
  display: flex;
  gap: 8px;
  justify-content: center;
}

/* Empty State */
.empty-state {
  text-align: center;
  padding: 60px 20px !important;
}

.empty-state i {
  font-size: 48px;
  color: var(--gray-300);
  margin-bottom: 16px;
}

.empty-state p {
  font-size: 16px;
  color: var(--gray-500);
  margin-bottom: 16px;
}

/* Pagination */
.pagination-wrapper {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  background: white;
  border-radius: var(--radius-lg);
  margin-top: 20px;
  box-shadow: var(--shadow);
}

.pagination-info {
  font-size: 14px;
  color: var(--gray-600);
  font-weight: 500;
}

.pagination-controls {
  display: flex;
  align-items: center;
  gap: 8px;
}

.pagination-btn {
  width: 36px;
  height: 36px;
  border-radius: var(--radius);
  border: 1px solid var(--gray-300);
  background: white;
  color: var(--gray-700);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.pagination-btn:hover:not(:disabled) {
  background: var(--gray-50);
  border-color: var(--primary);
}

.pagination-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.pagination-pages {
  display: flex;
  gap: 4px;
}

.pagination-page {
  min-width: 36px;
  height: 36px;
  padding: 0 8px;
  border-radius: var(--radius);
  border: none;
  background: transparent;
  color: var(--gray-700);
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.pagination-page:hover {
  background: var(--gray-100);
}

.pagination-page.active {
  background: var(--primary);
  color: white;
}

.page-size-select {
  padding: 8px 12px;
  border: 1px solid var(--gray-300);
  border-radius: var(--radius);
  font-size: 14px;
  color: var(--gray-700);
  cursor: pointer;
}

/* Detail Sidebar */
.detail-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  z-index: 999;
  backdrop-filter: blur(2px);
}

.detail-sidebar {
  position: fixed;
  top: 0;
  right: 0;
  bottom: 0;
  width: 500px;
  background: white;
  z-index: 1000;
  display: flex;
  flex-direction: column;
  box-shadow: var(--shadow-lg);
}

.sidebar-header {
  padding: 24px;
  border-bottom: 1px solid var(--gray-200);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.sidebar-header h3 {
  font-size: 20px;
  font-weight: 700;
  color: var(--gray-900);
  margin: 0;
}

.btn-close {
  width: 36px;
  height: 36px;
  border-radius: var(--radius);
  border: none;
  background: var(--gray-100);
  color: var(--gray-600);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.btn-close:hover {
  background: var(--gray-200);
}

.sidebar-content {
  flex: 1;
  overflow-y: auto;
  padding: 24px;
}

.detail-section {
  margin-bottom: 32px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.detail-section h4 {
  font-size: 16px;
  font-weight: 700;
  color: var(--gray-900);
  margin: 0 0 16px 0;
}

.detail-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
}

.detail-item {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.detail-item.full-width {
  grid-column: 1 / -1;
}

.detail-item label {
  font-size: 12px;
  font-weight: 600;
  color: var(--gray-500);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.detail-item .value {
  font-size: 14px;
  font-weight: 600;
  color: var(--gray-900);
}

.value.mono {
  font-family: monospace;
  font-size: 13px;
}

.value.amount-large {
  font-size: 24px;
  font-family: monospace;
}

.description-text {
  font-size: 14px;
  color: var(--gray-700);
  line-height: 1.6;
  margin: 0;
  padding: 16px;
  background: var(--gray-50);
  border-radius: var(--radius);
}

.sidebar-footer {
  padding: 24px;
  border-top: 1px solid var(--gray-200);
  display: flex;
  gap: 12px;
}

.sidebar-footer button {
  flex: 1;
}

/* Transitions */
.slide-right-enter-active,
.slide-right-leave-active {
  transition: transform 0.3s ease;
}

.slide-right-enter-from,
.slide-right-leave-to {
  transform: translateX(100%);
}

/* Responsive */
@media (max-width: 768px) {
  .transactions-page {
    padding: 16px;
  }

  .summary-grid {
    grid-template-columns: 1fr;
  }

  .filters-grid {
    grid-template-columns: 1fr;
  }

  .pagination-wrapper {
    flex-direction: column;
    gap: 16px;
  }

  .detail-sidebar {
    width: 100%;
  }

  .detail-grid {
    grid-template-columns: 1fr;
  }
}

.text-muted {
  color: var(--gray-400);
}
</style>
