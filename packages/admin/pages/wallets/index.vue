<template>
  <div class="wallet-page-container">
    <Breadcrumb :items="breadcrumbs" />
    <WalletSubnav />

    <!-- Page Header -->
    <div class="wallet-page-header">
      <div>
        <h1>{{ __wt('walletOverview') }}</h1>
        <p class="subtitle">{{ __wt('pageSubtitle') }}</p>
      </div>
      <div class="header-actions">
        <button
          @click="toggleWalletLang"
          class="wallet-btn secondary wallet-lang-toggle"
          :title="__wt('langToggle')"
        >
          <i class="fas fa-language"></i>
          {{ __wt('langToggle') }}
        </button>
        <button @click="exportData" class="wallet-btn secondary">
          <i class="fas fa-download"></i>
          {{ __wt('export') }}
        </button>
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
          {{ __wt(opt.i18n) }}
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
        <div class="stat-label">{{ __wt('kpiTopUp') }}</div>
        <div class="stat-value">฿{{ formatNumber(stats.topUpVolume) }}</div>
        <div class="stat-subtitle">{{ __wt('kpiTopUpHint', { count: formatInt(stats.topUpCount), period: localizedPeriodLabel }) }}</div>
        <div class="kpi-cta">
          {{ __wt('kpiCtaTransactions') }} <i class="fas fa-arrow-right"></i>
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
        <div class="stat-label">{{ __wt('kpiBonus') }}</div>
        <div class="stat-value">฿{{ formatNumber(stats.bonusVolume) }}</div>
        <div class="stat-subtitle">{{ __wt('kpiBonusHint', { count: formatInt(stats.bonusCount), period: localizedPeriodLabel }) }}</div>
        <div class="kpi-cta">
          {{ __wt('kpiCtaTransactions') }} <i class="fas fa-arrow-right"></i>
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
        <div class="stat-label">{{ __wt('kpiSpend') }}</div>
        <div class="stat-value">฿{{ formatNumber(stats.spendVolume) }}</div>
        <div class="stat-subtitle">{{ __wt('kpiSpendHint', { count: formatInt(stats.spendCount), period: localizedPeriodLabel }) }}</div>
        <div class="kpi-cta">
          {{ __wt('kpiCtaTransactions') }} <i class="fas fa-arrow-right"></i>
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
        <div class="stat-label">{{ __wt('kpiFloat') }}</div>
        <div class="stat-value">฿{{ formatNumber(stats.totalBalance) }}</div>
        <div class="stat-subtitle">
          {{ __wt('kpiFloatHint', { count: formatInt(stats.totalWallets) }) }}
        </div>
        <div class="kpi-cta">
          {{ __wt('kpiCtaWallets') }} <i class="fas fa-arrow-right"></i>
        </div>
      </button>
    </div>

    <!-- Branch Spend Breakdown -->
    <div class="branch-breakdown-card">
      <div class="branch-breakdown-header">
        <div>
          <h2>{{ __wt('branchTitle') }}</h2>
          <p>{{ __wt('branchSubtitle', { period: localizedPeriodLabel }) }}</p>
        </div>
        <div class="branch-total">
          <span class="branch-total-label">{{ __wt('branchTotal') }}</span>
          <span class="branch-total-value">฿{{ formatNumber(stats.spendVolume) }}</span>
        </div>
      </div>

      <div v-if="branchLoading" class="branch-empty">
        <i class="fas fa-spinner fa-spin"></i>
        {{ __wt('branchLoading') }}
      </div>
      <div v-else-if="byBranch.length === 0" class="branch-empty">
        <i class="fas fa-store-slash"></i>
        {{ __wt('branchEmpty') }}
      </div>
      <div v-else class="branch-rows">
        <div
          v-for="row in byBranch"
          :key="row.branch"
          :class="['branch-row', { 'branch-row-unattributed': row.unattributed }]"
          @click="handleBranchRowClick(row)"
        >
          <div class="branch-row-head">
            <span class="branch-name">
              <i v-if="row.unattributed" class="fas fa-question-circle unattributed-icon"></i>
              {{ row.unattributed ? __wt('branchUnattributed') : row.branch }}
              <span v-if="row.unattributed" class="unattributed-tag">{{ __wt('branchUnattributedTag') }}</span>
            </span>
            <span class="branch-amount">฿{{ formatNumber(row.volume) }}</span>
          </div>
          <div class="branch-bar-track">
            <div
              class="branch-bar-fill"
              :style="{ width: barWidth(row.volume) + '%' }"
            ></div>
          </div>
          <div class="branch-row-meta">
            <span>{{ __wt('branchTransactions', { count: formatInt(row.transactions) }) }}</span>
            <span>{{ __wt('branchAvg', { value: formatNumber(row.transactions ? row.volume / row.transactions : 0) }) }}</span>
            <span>{{ __wt('branchShareOfTotal', { percent: branchShare(row.volume) }) }}</span>
          </div>
          <div v-if="row.unattributed" class="unattributed-hint">
            {{ __wt('branchUnattributedHint') }}
          </div>
        </div>
      </div>
    </div>

    <!-- Staff Revenue -->
    <div class="staff-card">
      <div class="staff-header">
        <div>
          <h2>
            <i class="fas fa-user-tie"></i>
            {{ __wt('staffTitle') }}
          </h2>
          <p>{{ __wt('staffSubtitle') }}</p>
        </div>
        <div class="staff-totals">
          <div class="staff-tot">
            <span class="staff-tot-label">{{ __wt('staffTotalCharged') }}</span>
            <span class="staff-tot-value">฿{{ formatNumber(staffGrandTotal) }}</span>
          </div>
          <div class="staff-tot">
            <span class="staff-tot-label">{{ __wt('staffTotalStaff') }}</span>
            <span class="staff-tot-value">{{ formatInt(byStaff.length) }}</span>
          </div>
        </div>
      </div>

      <div v-if="byStaff.length === 0" class="staff-empty">
        <i class="fas fa-user-slash"></i>
        <p>{{ __wt('staffEmpty') }}</p>
      </div>

      <div v-else class="staff-table-wrap">
        <table class="staff-table">
          <thead>
            <tr>
              <th>{{ __wt('staffCol_staff') }}</th>
              <th class="num">{{ __wt('staffCol_transactions') }}</th>
              <th class="num">{{ __wt('staffCol_totalCharged') }}</th>
              <th class="num">{{ __wt('staffCol_avgPerTx') }}</th>
              <th class="num">{{ __wt('staffCol_share') }}</th>
              <th>{{ __wt('staffCol_lastActivity') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="s in byStaff"
              :key="s.staffId || 'unattributed'"
              :class="['staff-row', { 'staff-row-unattributed': s.unattributed }]"
              @click="goToStaff(s)"
            >
              <td>
                <template v-if="s.unattributed">
                  <span class="staff-tag-amber">
                    <i class="fas fa-question-circle"></i>
                    {{ __wt('staffUnattributed') }}
                  </span>
                </template>
                <template v-else>
                  <div class="staff-name">
                    {{ s.fullName || s.username || `Staff #${s.staffId}` }}
                  </div>
                  <code class="staff-id muted">{{ s.username ? `@${s.username}` : `#${s.staffId}` }}</code>
                </template>
              </td>
              <td class="num">{{ formatInt(s.txCount) }}</td>
              <td class="num"><strong>฿{{ formatNumber(s.totalCharged) }}</strong></td>
              <td class="num">฿{{ formatNumber(s.avgPerTx) }}</td>
              <td class="num">{{ staffShareOfTotal(s.totalCharged) }}%</td>
              <td>{{ formatRelativeDate(s.lastActivity) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Wallet Operations Section -->
    <div class="wallet-ops-section">
      <div class="wallet-ops-header">
        <h2>{{ __wt('walletsTitle') }}</h2>
        <p class="wallet-ops-sub" :class="{ 'is-loading': statsLoading }">
          <template v-if="statsLoading">
            <i class="fas fa-spinner fa-spin"></i>
            Loading wallet statistics…
          </template>
          <template v-else>
            {{ __wt('walletsSubtitle', {
              active: formatInt(stats.activeWallets),
              frozen: formatInt(stats.frozenWallets),
              suspended: formatInt(stats.suspendedWallets),
              pending: formatNumber(stats.pendingBalance),
            }) }}
          </template>
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
        {{ __wt('filterAll') }}
        <span class="chip-count" :class="{ loading: statsLoading }">
          <template v-if="statsLoading">…</template>
          <template v-else>{{ formatInt(stats.totalWallets) }}</template>
        </span>
      </button>
      <button
        @click="setStatus('active')"
        :class="['wallet-filter-chip', { active: filters.status === 'active' }]"
      >
        <i class="fas fa-check-circle"></i>
        {{ __wt('filterActive') }}
        <span class="chip-count" :class="{ loading: statsLoading }">
          <template v-if="statsLoading">…</template>
          <template v-else>{{ formatInt(stats.activeWallets) }}</template>
        </span>
      </button>
      <button
        @click="setStatus('frozen')"
        :class="['wallet-filter-chip', { active: filters.status === 'frozen' }]"
      >
        <i class="fas fa-snowflake"></i>
        {{ __wt('filterFrozen') }}
        <span class="chip-count" :class="{ loading: statsLoading }">
          <template v-if="statsLoading">…</template>
          <template v-else>{{ formatInt(stats.frozenWallets) }}</template>
        </span>
      </button>
      <button
        @click="setStatus('suspended')"
        :class="['wallet-filter-chip', { active: filters.status === 'suspended' }]"
      >
        <i class="fas fa-ban"></i>
        {{ __wt('filterSuspended') }}
        <span class="chip-count" :class="{ loading: statsLoading }">
          <template v-if="statsLoading">…</template>
          <template v-else>{{ formatInt(stats.suspendedWallets) }}</template>
        </span>
      </button>
      <button @click="resetFilters" class="wallet-filter-chip">
        <i class="fas fa-redo"></i>
        {{ __wt('filterReset') }}
      </button>
    </div>

    <!-- Advanced Filters -->
    <div class="wallet-filters-panel">
      <div class="wallet-filters-grid">
        <div class="wallet-filter-item">
          <label>
            <i class="fas fa-search"></i>
            {{ __wt('filterSearch') }}
          </label>
          <input
            v-model="filters.search"
            type="text"
            :placeholder="__wt('filterSearchPlaceholder')"
            @input="debouncedSearch"
          />
        </div>

        <div class="wallet-filter-item">
          <label>
            <i class="fas fa-coins"></i>
            {{ __wt('filterMinBalance') }}
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
            {{ __wt('filterMaxBalance') }}
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
              <i class="fas fa-hashtag"></i> {{ __wt('thUserId') }}
              <i :class="sortIcon('user_id')"></i>
            </th>
            <th><i class="fas fa-user"></i> {{ __wt('thName') }}</th>
            <th><i class="fas fa-envelope"></i> {{ __wt('thEmail') }}</th>
            <th class="sortable" @click="toggleSort('balance')">
              <i class="fas fa-wallet"></i> {{ __wt('thBalance') }}
              <i :class="sortIcon('balance')"></i>
            </th>
            <th><i class="fas fa-clock"></i> {{ __wt('thPending') }}</th>
            <th><i class="fas fa-info-circle"></i> {{ __wt('thStatus') }}</th>
            <th class="sortable" @click="toggleSort('last_transaction')">
              <i class="fas fa-calendar"></i> {{ __wt('thLastTransaction') }}
              <i :class="sortIcon('last_transaction')"></i>
            </th>
            <th><i class="fas fa-tools"></i> {{ __wt('thActions') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="8" class="wallet-loading">
              <i class="fas fa-spinner fa-spin"></i>
              <p>{{ __wt('loadingWallets') }}</p>
            </td>
          </tr>
          <tr v-else-if="wallets.length === 0">
            <td colspan="8" class="wallet-empty">
              <i class="fas fa-inbox"></i>
              <p>{{ __wt('noWalletsFound') }}</p>
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
                  {{ __wt('view') }}
                </nuxt-link>
                <button
                  v-if="wallet.status === 'active'"
                  @click="freezeWallet(wallet.userId)"
                  class="wallet-btn danger"
                  style="padding: 6px 12px; font-size: 12px;"
                >
                  <i class="fas fa-snowflake"></i>
                  {{ __wt('freeze') }}
                </button>
                <button
                  v-else
                  @click="unfreezeWallet(wallet.userId)"
                  class="wallet-btn success"
                  style="padding: 6px 12px; font-size: 12px;"
                >
                  <i class="fas fa-check"></i>
                  {{ __wt('unfreeze') }}
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
        {{ __wt('previous') }}
      </button>
      <span style="color: #6b7280; font-size: 14px;">
        {{ __wt('paginationShowing', {
          from: pagination.offset + 1,
          to: Math.min(pagination.offset + pagination.limit, pagination.total),
          total: pagination.total,
        }) }}
      </span>
      <button
        @click="nextPage"
        :disabled="!pagination.hasMore"
        class="wallet-btn secondary"
      >
        {{ __wt('next') }}
        <i class="fas fa-chevron-right"></i>
      </button>
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
      // True between first mount and the first loadStats() resolve.
      // Prevents the Overview from rendering stale zero counts before
      // the real data arrives.
      statsLoading: true,
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
        { key: 'today', i18n: 'periodToday' },
        { key: '7d', i18n: 'period7d' },
        { key: 'mtd', i18n: 'periodMtd' },
        { key: '30d', i18n: 'period30d' },
        { key: 'custom', i18n: 'periodCustom' },
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
      byStaff: [],
      searchTimeout: null,
    };
  },
  computed: {
    periodDisplayLabel() {
      const range = this.resolvePeriodRange();
      if (!range) return '';
      const from = this.$moment(range.from).tz('Asia/Bangkok');
      const to = this.$moment(range.to).tz('Asia/Bangkok');
      if (from.isSame(to, 'day')) return from.format('MMM D, YYYY');
      return `${from.format('MMM D')} – ${to.format('MMM D, YYYY')}`;
    },
    // Localized version of the period for use inside subtitles. Uses the
    // i18n key when the period matches a preset, otherwise echoes the
    // server-derived label (date range).
    localizedPeriodLabel() {
      const opt = this.periodOptions.find((o) => o.key === this.period);
      if (opt && this.period !== 'custom') return this.__wt(opt.i18n);
      return this.periodDisplayLabel || this.stats.periodLabel;
    },
    maxBranchVolume() {
      if (!this.byBranch.length) return 0;
      return this.byBranch.reduce((m, r) => (r.volume > m ? r.volume : m), 0);
    },
    staffGrandTotal() {
      return (this.byStaff || []).reduce((s, r) => s + (r.totalCharged || 0), 0);
    },
  },
  async mounted() {
    this.__hydrateWalletUiLang();
    this.applyWalletQueryFilters();
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
          // MySQL returns SUM() / COUNT() results as DECIMAL/BIGINT
          // strings via mysql2. Without Number() coercion, the "+" in
          // the totalWallets computation below concatenates strings
          // ("133641" + "0" + "0" = "13364100") instead of adding —
          // which is what produced BUG-09's 100× inflation. Coerce
          // every numeric stat at the boundary.
          const activeWallets = Number(summary.activeWallets) || 0;
          const frozenWallets = Number(summary.frozenWallets) || 0;
          const suspendedWallets = Number(summary.suspendedWallets) || 0;
          const totalWallets = activeWallets + frozenWallets + suspendedWallets;

          this.stats = {
            totalBalance: Number(summary.totalWalletBalance) || 0,
            totalWallets,
            activeWallets,
            frozenWallets,
            suspendedWallets,
            topUpVolume: Number(txSummary.topUpVolume) || 0,
            topUpCount: Number(txSummary.topUpCount) || 0,
            bonusVolume: Number(txSummary.bonusVolume) || 0,
            bonusCount: Number(txSummary.bonusCount) || 0,
            spendVolume: Number(txSummary.spendVolume) || 0,
            spendCount: Number(txSummary.spendCount) || 0,
            periodLabel: this.derivePeriodLabel(data.period),
            pendingBalance: Number(summary.totalPendingBalance) || 0,
            frozenBalance: Number(summary.totalFrozenBalance) || 0,
          };

          this.deltas = {
            topUp: this.calcDelta(txSummary.topUpVolume, prevTx.topUpVolume),
            bonus: this.calcDelta(txSummary.bonusVolume, prevTx.bonusVolume),
            spend: this.calcDelta(txSummary.spendVolume, prevTx.spendVolume),
          };

          this.byBranch = Array.isArray(data.byBranch) ? data.byBranch : [];
          this.byStaff = Array.isArray(data.byStaff) ? data.byStaff : [];
        }
      } catch (error) {
        console.error('Error loading stats:', error);
      } finally {
        this.branchLoading = false;
        this.statsLoading = false;
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

    handleBranchRowClick(row) {
      const range = this.resolvePeriodRange();
      const dateParams = range
        ? { fromDate: range.from, toDate: range.to }
        : {};

      this.$router.push({
        path: '/wallets/transactions',
        query: {
          types: 'store_payment,beer_machine_payment',
          ...(row.unattributed
            ? { branchMissing: '1' }
            : { branch: row.branch }),
          ...dateParams,
          periodLabel: this.stats.periodLabel,
        },
      });
    },

    staffShareOfTotal(amount) {
      const total = this.staffGrandTotal;
      if (!total) return '0.0';
      return ((amount / total) * 100).toFixed(1);
    },

    goToStaff(staff) {
      const id = staff.unattributed ? '__unattributed__' : staff.staffId;
      const range = this.resolvePeriodRange();
      const query = {};
      if (range) {
        query.fromDate = range.from;
        query.toDate = range.to;
      }
      this.$router.push({
        path: `/wallets/staff/${encodeURIComponent(id)}`,
        query,
      });
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

    toggleWalletLang() {
      const next = this.$store.state.walletUiLang === 'th' ? 'en' : 'th';
      this.__setWalletUiLang(next);
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
      if (!date) return this.__wt('never');
      return this.$moment(date).tz('Asia/Bangkok').format('MMM D, YYYY HH:mm');
    },

    formatRelativeDate(date) {
      if (!date) return '—';
      return this.$moment(date).tz('Asia/Bangkok').fromNow();
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

.chip-count.loading {
  opacity: 0.6;
  font-style: italic;
  letter-spacing: 0.5px;
}

.wallet-ops-sub.is-loading {
  opacity: 0.7;
  font-style: italic;

  i { margin-right: 6px; }
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

.branch-row-unattributed {
  background: rgba(245, 158, 11, 0.06);
  border: 1px dashed rgba(245, 158, 11, 0.45);
}

.branch-row-unattributed:hover {
  background: rgba(245, 158, 11, 0.12);
}

.branch-row-unattributed .branch-name {
  color: #92400e;
}

.branch-row-unattributed .branch-amount {
  color: #92400e;
}

.branch-row-unattributed .branch-bar-fill {
  background: linear-gradient(90deg, #f59e0b 0%, #fbbf24 100%);
}

.unattributed-icon {
  color: #f59e0b;
  margin-right: 6px;
}

.unattributed-tag {
  display: inline-block;
  margin-left: 8px;
  padding: 2px 8px;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #92400e;
  background: rgba(245, 158, 11, 0.18);
  border-radius: 999px;
  vertical-align: middle;
}

.unattributed-hint {
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px dashed rgba(245, 158, 11, 0.4);
  font-size: 12px;
  color: #78350f;
  line-height: 1.5;
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

.wallet-lang-toggle {
  font-weight: 600;
  letter-spacing: 0.02em;
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

/* Staff Revenue card (mirrors the same card on /wallets/reports) */
.staff-card {
  background: #fff;
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 24px;
  border: 1px solid #E2E8F0;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
}

.staff-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.staff-header h2 {
  margin: 0 0 4px;
  font-size: 20px;
  font-weight: 700;
  color: #063F48;
}
.staff-header h2 i { margin-right: 8px; color: #7C5CFF; }

.staff-header p {
  margin: 0;
  font-size: 13px;
  color: #6B7280;
}

.staff-totals { display: flex; gap: 20px; flex-wrap: wrap; }
.staff-tot { text-align: right; }
.staff-tot-label {
  display: block;
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #6B7280;
  font-weight: 600;
}
.staff-tot-value {
  display: block;
  font-size: 18px;
  font-weight: 700;
  color: #7C5CFF;
}

.staff-empty {
  padding: 48px 20px;
  text-align: center;
  color: #6B7280;
}
.staff-empty i { font-size: 32px; display: block; margin-bottom: 8px; color: #D1D5DB; }

.staff-table-wrap {
  border: 1px solid #E5E7EB;
  border-radius: 12px;
  overflow-x: auto;
}

.staff-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  font-variant-numeric: tabular-nums;
}

.staff-table thead th {
  text-align: left;
  padding: 12px;
  background: #F7FAFC;
  font-weight: 600;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: #6B7280;
  border-bottom: 1px solid #E5E7EB;
  white-space: nowrap;
}
.staff-table th.num, .staff-table td.num { text-align: right; }

.staff-table tbody td {
  padding: 12px;
  border-bottom: 1px solid #F1F5F9;
  color: #1F2937;
}

.staff-row { cursor: pointer; transition: background 0.12s ease; }
.staff-row:hover td { background: #F9FAFB; }

.staff-row-unattributed { background: rgba(245, 158, 11, 0.04); }
.staff-row-unattributed:hover td { background: rgba(245, 158, 11, 0.1); }

.staff-name { font-weight: 600; color: #063F48; }
.staff-id {
  font-family: 'SF Mono', Menlo, Consolas, monospace;
  font-size: 11px;
  color: #9CA3AF;
}
.staff-tag-amber {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  font-size: 12px;
  font-weight: 600;
  color: #92400E;
  background: rgba(245, 158, 11, 0.15);
  border-radius: 999px;
}
</style>
