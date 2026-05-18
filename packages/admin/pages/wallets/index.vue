<template>
  <div class="wallet-page-container">
    <Breadcrumb :items="breadcrumbs" />

    <!-- Page Header -->
    <div class="wallet-page-header">
      <div>
        <h1>Wallet Overview</h1>
        <p class="subtitle">Top-ups, bonuses, branch revenue, and outstanding float</p>
      </div>
      <div class="header-actions">
        <button @click="exportData" class="wallet-btn secondary">
          <i class="fas fa-download"></i>
          Export
        </button>
        <div class="wallet-more-menu">
          <button @click="moreMenuOpen = !moreMenuOpen" class="wallet-btn secondary">
            <i class="fas fa-ellipsis-h"></i>
            More
          </button>
          <div v-if="moreMenuOpen" class="wallet-more-dropdown">
            <nuxt-link to="/wallets/transactions" @click.native="closeMoreMenu">
              <i class="fas fa-list"></i> All Transactions
            </nuxt-link>
            <nuxt-link to="/wallets/reports" @click.native="closeMoreMenu">
              <i class="fas fa-chart-bar"></i> Reports
            </nuxt-link>
            <nuxt-link to="/wallets/vouchers" @click.native="closeMoreMenu">
              <i class="fas fa-gift"></i> Vouchers
            </nuxt-link>
            <nuxt-link to="/wallets/settings" @click.native="closeMoreMenu">
              <i class="fas fa-cog"></i> Settings
            </nuxt-link>
          </div>
        </div>
      </div>
    </div>

    <!-- Date Range Picker -->
    <div class="wallet-period-bar">
      <div class="period-options">
        <button
          v-for="opt in periodOptions"
          :key="opt.key"
          :class="['period-btn', { active: period === opt.key }]"
          @click="setPeriod(opt.key)"
        >
          {{ opt.label }}
        </button>
      </div>
      <div class="period-range" v-if="period === 'custom'">
        <input type="date" v-model="customRange.from" @change="applyCustomRange" />
        <span>—</span>
        <input type="date" v-model="customRange.to" @change="applyCustomRange" />
      </div>
      <div class="period-range-display" v-else>
        {{ periodDisplayLabel }}
      </div>
    </div>

    <!-- Financial KPI Cards (click to drill into details) -->
    <div class="wallet-stats-grid">
      <button
        type="button"
        class="wallet-stat-card kpi-card kpi-positive kpi-clickable"
        @click="drillInto('topUp')"
        :aria-label="`View top-up transactions for ${stats.periodLabel}`"
      >
        <div class="stat-header">
          <div class="stat-icon success">
            <i class="fas fa-arrow-down"></i>
          </div>
          <span :class="['kpi-delta', deltaClass(deltas.topUp)]" v-if="deltas.topUp !== null">
            <i :class="deltaIcon(deltas.topUp)"></i>
            {{ formatDelta(deltas.topUp) }}
          </span>
        </div>
        <div class="stat-label">Total Top-Up</div>
        <div class="stat-value">฿{{ formatNumber(stats.topUpVolume) }}</div>
        <div class="stat-subtitle">{{ formatInt(stats.topUpCount) }} top-ups · {{ stats.periodLabel }}</div>
        <div class="kpi-cta">
          View transactions <i class="fas fa-arrow-right"></i>
        </div>
      </button>

      <button
        type="button"
        class="wallet-stat-card kpi-card kpi-warn kpi-clickable"
        @click="drillInto('bonus')"
        :aria-label="`View bonus transactions for ${stats.periodLabel}`"
      >
        <div class="stat-header">
          <div class="stat-icon warning">
            <i class="fas fa-gift"></i>
          </div>
          <span :class="['kpi-delta', deltaClass(deltas.bonus)]" v-if="deltas.bonus !== null">
            <i :class="deltaIcon(deltas.bonus)"></i>
            {{ formatDelta(deltas.bonus) }}
          </span>
        </div>
        <div class="stat-label">Bonus &amp; Promotion</div>
        <div class="stat-value">฿{{ formatNumber(stats.bonusVolume) }}</div>
        <div class="stat-subtitle">{{ formatInt(stats.bonusCount) }} bonuses · {{ stats.periodLabel }}</div>
        <div class="kpi-cta">
          View transactions <i class="fas fa-arrow-right"></i>
        </div>
      </button>

      <button
        type="button"
        class="wallet-stat-card kpi-card kpi-negative kpi-clickable"
        @click="drillInto('spend')"
        :aria-label="`View spend transactions for ${stats.periodLabel}`"
      >
        <div class="stat-header">
          <div class="stat-icon info">
            <i class="fas fa-store"></i>
          </div>
          <span :class="['kpi-delta', deltaClass(deltas.spend)]" v-if="deltas.spend !== null">
            <i :class="deltaIcon(deltas.spend)"></i>
            {{ formatDelta(deltas.spend) }}
          </span>
        </div>
        <div class="stat-label">Total Spend</div>
        <div class="stat-value">฿{{ formatNumber(stats.spendVolume) }}</div>
        <div class="stat-subtitle">{{ formatInt(stats.spendCount) }} payments · {{ stats.periodLabel }}</div>
        <div class="kpi-cta">
          View transactions <i class="fas fa-arrow-right"></i>
        </div>
      </button>

      <button
        type="button"
        class="wallet-stat-card kpi-card kpi-neutral kpi-clickable"
        @click="drillInto('float')"
        aria-label="View wallets sorted by balance"
      >
        <div class="stat-header">
          <div class="stat-icon info">
            <i class="fas fa-wallet"></i>
          </div>
        </div>
        <div class="stat-label">Wallet Float</div>
        <div class="stat-value">฿{{ formatNumber(stats.totalBalance) }}</div>
        <div class="stat-subtitle">
          Outstanding liability · {{ formatInt(stats.totalWallets) }} wallets
        </div>
        <div class="kpi-cta">
          View wallets <i class="fas fa-arrow-right"></i>
        </div>
      </button>
    </div>

    <!-- Branch Spend Breakdown -->
    <div class="branch-breakdown-card">
      <div class="branch-breakdown-header">
        <div>
          <h2>Spend by Branch</h2>
          <p>How much customers spent at each location · {{ stats.periodLabel }}</p>
        </div>
        <div class="branch-total">
          <span class="branch-total-label">Total</span>
          <span class="branch-total-value">฿{{ formatNumber(stats.spendVolume) }}</span>
        </div>
      </div>

      <div v-if="branchLoading" class="branch-empty">
        <i class="fas fa-spinner fa-spin"></i>
        Loading branch data…
      </div>
      <div v-else-if="byBranch.length === 0" class="branch-empty">
        <i class="fas fa-store-slash"></i>
        No branch spend recorded for this period.
      </div>
      <div v-else class="branch-rows">
        <div
          v-for="row in byBranch"
          :key="row.branch"
          class="branch-row"
          @click="filterByBranch(row.branch)"
        >
          <div class="branch-row-head">
            <span class="branch-name">{{ row.branch }}</span>
            <span class="branch-amount">฿{{ formatNumber(row.volume) }}</span>
          </div>
          <div class="branch-bar-track">
            <div
              class="branch-bar-fill"
              :style="{ width: barWidth(row.volume) + '%' }"
            ></div>
          </div>
          <div class="branch-row-meta">
            <span>{{ formatInt(row.transactions) }} transactions</span>
            <span>Avg ฿{{ formatNumber(row.transactions ? row.volume / row.transactions : 0) }}</span>
            <span>{{ branchShare(row.volume) }}% of total</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Wallet Operations Section -->
    <div class="wallet-ops-section">
      <div class="wallet-ops-header">
        <h2>Wallets</h2>
        <p class="wallet-ops-sub">
          {{ formatInt(stats.activeWallets) }} active ·
          {{ formatInt(stats.frozenWallets) }} frozen ·
          {{ formatInt(stats.suspendedWallets) }} suspended ·
          ฿{{ formatNumber(stats.pendingBalance) }} pending
        </p>
      </div>
    </div>

    <!-- Quick Filters -->
    <div class="wallet-filter-chips">
      <button
        @click="setStatus('')"
        :class="['wallet-filter-chip', { active: filters.status === '' }]"
      >
        <i class="fas fa-list"></i>
        All Wallets
        <span class="chip-count">{{ formatInt(stats.totalWallets) }}</span>
      </button>
      <button
        @click="setStatus('active')"
        :class="['wallet-filter-chip', { active: filters.status === 'active' }]"
      >
        <i class="fas fa-check-circle"></i>
        Active
        <span class="chip-count">{{ formatInt(stats.activeWallets) }}</span>
      </button>
      <button
        @click="setStatus('frozen')"
        :class="['wallet-filter-chip', { active: filters.status === 'frozen' }]"
      >
        <i class="fas fa-snowflake"></i>
        Frozen
        <span class="chip-count">{{ formatInt(stats.frozenWallets) }}</span>
      </button>
      <button
        @click="setStatus('suspended')"
        :class="['wallet-filter-chip', { active: filters.status === 'suspended' }]"
      >
        <i class="fas fa-ban"></i>
        Suspended
        <span class="chip-count">{{ formatInt(stats.suspendedWallets) }}</span>
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

      </div>
    </div>

    <!-- Wallets Table -->
    <div class="wallet-table-container">
      <table class="wallet-table">
        <thead>
          <tr>
            <th class="sortable" @click="toggleSort('user_id')">
              <i class="fas fa-hashtag"></i> User ID
              <i :class="sortIcon('user_id')"></i>
            </th>
            <th><i class="fas fa-user"></i> Name</th>
            <th><i class="fas fa-envelope"></i> Email</th>
            <th class="sortable" @click="toggleSort('balance')">
              <i class="fas fa-wallet"></i> Balance
              <i :class="sortIcon('balance')"></i>
            </th>
            <th><i class="fas fa-clock"></i> Pending</th>
            <th><i class="fas fa-info-circle"></i> Status</th>
            <th class="sortable" @click="toggleSort('last_transaction')">
              <i class="fas fa-calendar"></i> Last Transaction
              <i :class="sortIcon('last_transaction')"></i>
            </th>
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
        { label: 'Wallet Overview' },
      ],
      wallets: [],
      loading: false,
      branchLoading: false,
      moreMenuOpen: false,
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
      period: 'mtd',
      customRange: {
        from: '',
        to: '',
      },
      periodOptions: [
        { key: 'today', label: 'Today' },
        { key: '7d', label: '7d' },
        { key: 'mtd', label: 'MTD' },
        { key: '30d', label: '30d' },
        { key: 'custom', label: 'Custom' },
      ],
      stats: {
        totalBalance: 0,
        totalWallets: 0,
        activeWallets: 0,
        frozenWallets: 0,
        suspendedWallets: 0,
        topUpVolume: 0,
        topUpCount: 0,
        bonusVolume: 0,
        bonusCount: 0,
        spendVolume: 0,
        spendCount: 0,
        periodLabel: 'MTD',
        pendingBalance: 0,
        frozenBalance: 0,
      },
      deltas: {
        topUp: null,
        bonus: null,
        spend: null,
      },
      byBranch: [],
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
    periodDisplayLabel() {
      const range = this.resolvePeriodRange();
      if (!range) return '';
      const from = this.$moment(range.from).tz('Asia/Bangkok');
      const to = this.$moment(range.to).tz('Asia/Bangkok');
      if (from.isSame(to, 'day')) return from.format('MMM D, YYYY');
      return `${from.format('MMM D')} – ${to.format('MMM D, YYYY')}`;
    },
    maxBranchVolume() {
      if (!this.byBranch.length) return 0;
      return this.byBranch.reduce((m, r) => (r.volume > m ? r.volume : m), 0);
    },
  },
  async mounted() {
    document.addEventListener('click', this.handleDocumentClick);
    this.applyWalletQueryFilters();
    await this.loadWallets();
    await this.loadStats();
  },
  beforeDestroy() {
    document.removeEventListener('click', this.handleDocumentClick);
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
      this.branchLoading = true;
      try {
        const range = this.resolvePeriodRange();
        const params = { reportType: 'summary' };
        if (range) {
          params.fromDate = range.from;
          params.toDate = range.to;
        }

        const response = await this.$walletService.getReports(params);

        if (response.success) {
          const data = response.data;
          const summary = data.summary || {};
          const txSummary = data.transactionSummary || {};
          const prevTx = data.previousTransactionSummary || {};
          const totalWallets =
            (summary.activeWallets || 0) +
            (summary.frozenWallets || 0) +
            (summary.suspendedWallets || 0);

          this.stats = {
            totalBalance: summary.totalWalletBalance || 0,
            totalWallets,
            activeWallets: summary.activeWallets || 0,
            frozenWallets: summary.frozenWallets || 0,
            suspendedWallets: summary.suspendedWallets || 0,
            topUpVolume: txSummary.topUpVolume || 0,
            topUpCount: txSummary.topUpCount || 0,
            bonusVolume: txSummary.bonusVolume || 0,
            bonusCount: txSummary.bonusCount || 0,
            spendVolume: txSummary.spendVolume || 0,
            spendCount: txSummary.spendCount || 0,
            periodLabel: this.derivePeriodLabel(data.period),
            pendingBalance: summary.totalPendingBalance || 0,
            frozenBalance: summary.totalFrozenBalance || 0,
          };

          this.deltas = {
            topUp: this.calcDelta(txSummary.topUpVolume, prevTx.topUpVolume),
            bonus: this.calcDelta(txSummary.bonusVolume, prevTx.bonusVolume),
            spend: this.calcDelta(txSummary.spendVolume, prevTx.spendVolume),
          };

          this.byBranch = Array.isArray(data.byBranch) ? data.byBranch : [];
        }
      } catch (error) {
        console.error('Error loading stats:', error);
      } finally {
        this.branchLoading = false;
      }
    },

    resolvePeriodRange() {
      const now = this.$moment().tz('Asia/Bangkok');
      let from, to;
      switch (this.period) {
        case 'today':
          from = now.clone().startOf('day');
          to = now.clone().endOf('day');
          break;
        case '7d':
          from = now.clone().subtract(6, 'days').startOf('day');
          to = now.clone().endOf('day');
          break;
        case '30d':
          from = now.clone().subtract(29, 'days').startOf('day');
          to = now.clone().endOf('day');
          break;
        case 'mtd':
          from = now.clone().startOf('month');
          to = now.clone().endOf('day');
          break;
        case 'custom':
          if (!this.customRange.from || !this.customRange.to) return null;
          from = this.$moment.tz(this.customRange.from, 'Asia/Bangkok').startOf('day');
          to = this.$moment.tz(this.customRange.to, 'Asia/Bangkok').endOf('day');
          break;
        default:
          return null;
      }
      return { from: from.toISOString(), to: to.toISOString() };
    },

    setPeriod(key) {
      this.period = key;
      if (key !== 'custom') {
        this.loadStats();
      }
    },

    applyCustomRange() {
      if (this.customRange.from && this.customRange.to) {
        this.loadStats();
      }
    },

    calcDelta(current, previous) {
      const cur = parseFloat(current) || 0;
      const prev = parseFloat(previous) || 0;
      if (prev === 0) {
        if (cur === 0) return 0;
        return null;
      }
      return ((cur - prev) / prev) * 100;
    },

    deltaClass(value) {
      if (value === null || value === 0) return 'flat';
      return value > 0 ? 'up' : 'down';
    },

    deltaIcon(value) {
      if (value === null || value === 0) return 'fas fa-minus';
      return value > 0 ? 'fas fa-arrow-up' : 'fas fa-arrow-down';
    },

    formatDelta(value) {
      if (value === null) return '—';
      const abs = Math.abs(value);
      return `${abs.toFixed(1)}%`;
    },

    barWidth(volume) {
      if (!this.maxBranchVolume) return 0;
      const pct = (volume / this.maxBranchVolume) * 100;
      return Math.max(2, pct);
    },

    branchShare(volume) {
      if (!this.stats.spendVolume) return '0.0';
      return ((volume / this.stats.spendVolume) * 100).toFixed(1);
    },

    filterByBranch(branch) {
      this.filters.search = branch;
      this.pagination.offset = 0;
      this.loadWallets();
    },

    applyWalletQueryFilters() {
      const q = this.$route.query || {};
      if (q.sortBy) this.filters.sortBy = q.sortBy;
      if (q.sortOrder) this.filters.sortOrder = q.sortOrder;
    },

    drillInto(kpi) {
      const range = this.resolvePeriodRange();
      const dateParams = range
        ? { fromDate: range.from, toDate: range.to }
        : {};

      if (kpi === 'float') {
        this.$router.push({
          path: '/wallets',
          query: { sortBy: 'balance', sortOrder: 'desc' },
        });
        return;
      }

      const typeQuery = {
        topUp: { type: 'top_up' },
        bonus: { type: 'bonus' },
        spend: { types: 'store_payment,beer_machine_payment' },
      }[kpi];

      this.$router.push({
        path: '/wallets/transactions',
        query: {
          ...typeQuery,
          ...dateParams,
          periodLabel: this.stats.periodLabel,
        },
      });
    },

    closeMoreMenu() {
      this.moreMenuOpen = false;
    },

    handleDocumentClick(event) {
      if (!this.moreMenuOpen) return;
      const menu = this.$el.querySelector('.wallet-more-menu');
      if (menu && !menu.contains(event.target)) {
        this.moreMenuOpen = false;
      }
    },

    derivePeriodLabel(period) {
      if (!period || !period.from || !period.to) return 'MTD';
      const from = this.$moment(period.from).tz('Asia/Bangkok');
      const to = this.$moment(period.to).tz('Asia/Bangkok');
      if (from.isSame(to, 'day')) return from.format('MMM D');
      if (from.date() === 1 && from.isSame(to, 'month')) return 'MTD';
      return `${from.format('MMM D')} – ${to.format('MMM D')}`;
    },

    debouncedSearch() {
      clearTimeout(this.searchTimeout);
      this.searchTimeout = setTimeout(() => {
        this.pagination.offset = 0;
        this.loadWallets();
      }, 500);
    },

    setStatus(status) {
      this.filters.status = status;
      this.pagination.offset = 0;
      this.loadWallets();
    },

    toggleSort(column) {
      if (this.filters.sortBy === column) {
        this.filters.sortOrder = this.filters.sortOrder === 'asc' ? 'desc' : 'asc';
      } else {
        this.filters.sortBy = column;
        this.filters.sortOrder = 'desc';
      }
      this.pagination.offset = 0;
      this.loadWallets();
    },

    sortIcon(column) {
      if (this.filters.sortBy !== column) return 'fas fa-sort sort-icon inactive';
      return this.filters.sortOrder === 'asc'
        ? 'fas fa-sort-up sort-icon active'
        : 'fas fa-sort-down sort-icon active';
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
          this.loadStats();
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
            this.loadStats();
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
            this.loadStats();
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

    formatInt(value) {
      if (value === null || value === undefined) return '0';
      return parseInt(value, 10).toLocaleString('en-US');
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

.chip-count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 22px;
  padding: 0 8px;
  margin-left: 6px;
  font-size: 12px;
  font-weight: 600;
  line-height: 1;
  height: 20px;
  border-radius: 999px;
  background: rgba(0, 0, 0, 0.08);
  color: inherit;
}

.wallet-filter-chip.active .chip-count {
  background: rgba(255, 255, 255, 0.25);
}

.wallet-table th.sortable {
  cursor: pointer;
  user-select: none;
}

.wallet-table th.sortable:hover {
  background: rgba(23, 151, 173, 0.08);
}

.sort-icon {
  margin-left: 6px;
  font-size: 11px;
}

.sort-icon.inactive {
  opacity: 0.35;
}

.sort-icon.active {
  color: #1797AD;
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

.wallet-period-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 20px;
  padding: 12px 16px;
  background: #fff;
  border-radius: 12px;
  border: 1px solid #e5e7eb;
  flex-wrap: wrap;
}

.period-options {
  display: inline-flex;
  background: #f1f5f9;
  border-radius: 999px;
  padding: 4px;
  gap: 2px;
}

.period-btn {
  padding: 6px 14px;
  font-size: 13px;
  font-weight: 600;
  color: #475569;
  background: transparent;
  border: none;
  border-radius: 999px;
  cursor: pointer;
  transition: background 0.15s ease, color 0.15s ease;
}

.period-btn:hover {
  background: rgba(23, 151, 173, 0.08);
}

.period-btn.active {
  background: #1797AD;
  color: #fff;
}

.period-range {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.period-range input {
  padding: 6px 10px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 13px;
}

.period-range-display {
  font-size: 13px;
  color: #6b7280;
  font-weight: 500;
}

.kpi-card {
  position: relative;
}

.kpi-card .stat-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.kpi-clickable {
  cursor: pointer;
  text-align: left;
  font: inherit;
  width: 100%;
  border: 1px solid transparent;
  transition: transform 0.12s ease, box-shadow 0.15s ease, border-color 0.15s ease;
}

.kpi-clickable:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 28px rgba(6, 63, 72, 0.12);
  border-color: rgba(23, 151, 173, 0.35);
}

.kpi-clickable:active {
  transform: translateY(0);
  box-shadow: 0 4px 12px rgba(6, 63, 72, 0.1);
}

.kpi-clickable:focus-visible {
  outline: 2px solid #1797AD;
  outline-offset: 2px;
}

.kpi-cta {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px dashed #e5e7eb;
  font-size: 12px;
  font-weight: 600;
  color: #6b7280;
  display: flex;
  align-items: center;
  justify-content: space-between;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  transition: color 0.15s ease;
}

.kpi-cta i {
  font-size: 10px;
  transition: transform 0.15s ease;
}

.kpi-clickable:hover .kpi-cta {
  color: #1797AD;
}

.kpi-clickable:hover .kpi-cta i {
  transform: translateX(4px);
}

.kpi-delta {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  font-weight: 700;
  padding: 4px 8px;
  border-radius: 999px;
}

.kpi-delta.up {
  background: rgba(16, 185, 129, 0.12);
  color: #047857;
}

.kpi-delta.down {
  background: rgba(239, 68, 68, 0.12);
  color: #b91c1c;
}

.kpi-delta.flat {
  background: rgba(107, 114, 128, 0.12);
  color: #4b5563;
}

.kpi-positive .stat-value {
  color: #047857;
}

.kpi-warn .stat-value {
  color: #b45309;
}

.kpi-negative .stat-value {
  color: #1797AD;
}

.branch-breakdown-card {
  background: #fff;
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 24px;
  border: 1px solid #e5e7eb;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.04);
}

.branch-breakdown-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20px;
  gap: 16px;
  flex-wrap: wrap;
}

.branch-breakdown-header h2 {
  margin: 0 0 4px;
  font-size: 18px;
  color: #063F48;
}

.branch-breakdown-header p {
  margin: 0;
  font-size: 13px;
  color: #6b7280;
}

.branch-total {
  text-align: right;
}

.branch-total-label {
  display: block;
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #6b7280;
  font-weight: 600;
}

.branch-total-value {
  font-size: 20px;
  font-weight: 700;
  color: #1797AD;
}

.branch-empty {
  padding: 40px 20px;
  text-align: center;
  color: #6b7280;
  font-size: 14px;
}

.branch-empty i {
  margin-right: 8px;
  font-size: 18px;
}

.branch-rows {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.branch-row {
  padding: 12px 14px;
  border-radius: 12px;
  background: #f9fafb;
  cursor: pointer;
  transition: background 0.15s ease, transform 0.05s ease;
}

.branch-row:hover {
  background: #f1f5f9;
}

.branch-row:active {
  transform: scale(0.998);
}

.branch-row-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 8px;
}

.branch-name {
  font-size: 14px;
  font-weight: 600;
  color: #111827;
}

.branch-amount {
  font-size: 16px;
  font-weight: 700;
  color: #063F48;
}

.branch-bar-track {
  height: 8px;
  background: rgba(23, 151, 173, 0.1);
  border-radius: 999px;
  overflow: hidden;
}

.branch-bar-fill {
  height: 100%;
  background: linear-gradient(90deg, #1797AD 0%, #14b8a6 100%);
  border-radius: 999px;
  transition: width 0.4s ease;
}

.branch-row-meta {
  display: flex;
  gap: 16px;
  margin-top: 8px;
  font-size: 12px;
  color: #6b7280;
}

.wallet-ops-section {
  margin-top: 8px;
  margin-bottom: 12px;
}

.wallet-ops-header h2 {
  margin: 0 0 4px;
  font-size: 18px;
  color: #063F48;
}

.wallet-ops-sub {
  margin: 0;
  font-size: 13px;
  color: #6b7280;
}

.wallet-more-menu {
  position: relative;
  display: inline-block;
}

.wallet-more-dropdown {
  position: absolute;
  top: calc(100% + 6px);
  right: 0;
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.12);
  padding: 6px;
  min-width: 200px;
  z-index: 100;
}

.wallet-more-dropdown a {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  font-size: 14px;
  color: #374151;
  text-decoration: none;
  border-radius: 8px;
  transition: background 0.12s ease;
}

.wallet-more-dropdown a:hover {
  background: #f3f4f6;
  color: #1797AD;
}

@media (max-width: 768px) {
  .wallet-period-bar {
    flex-direction: column;
    align-items: stretch;
  }

  .period-options {
    overflow-x: auto;
  }

  .branch-row-meta {
    flex-wrap: wrap;
    gap: 8px 16px;
  }
}
</style>
