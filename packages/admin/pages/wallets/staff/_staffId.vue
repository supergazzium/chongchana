<template>
  <div class="wallet-page-container">
    <Breadcrumb :items="breadcrumbs" />
    <WalletSubnav />

    <div class="wallet-page-header">
      <div>
        <h1>{{ __wt('staffDetailTitle') }}</h1>
        <p class="subtitle">
          <template v-if="staff && staff.unattributed">
            {{ __wt('staffUnattributed') }}
          </template>
          <template v-else-if="staff">
            {{ staff.fullName || staff.username || `Staff #${staff.staffId}` }}
            <code v-if="staff.username" class="staff-id-chip">@{{ staff.username }}</code>
            <code v-else class="staff-id-chip">#{{ staff.staffId }}</code>
          </template>
          <template v-else>—</template>
        </p>
      </div>
      <div class="header-actions">
        <nuxt-link to="/wallets/reports" class="wallet-btn secondary">
          <i class="fas fa-arrow-left"></i>
          {{ __wt('staffDetailBackToReports') }}
        </nuxt-link>
        <button
          @click="toggleWalletLang"
          class="wallet-btn secondary wallet-lang-toggle"
          :title="__wt('langToggle')"
        >
          <i class="fas fa-language"></i>
          {{ __wt('langToggle') }}
        </button>
      </div>
    </div>

    <!-- Date range picker (defaults from URL on first load, then editable) -->
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
      <div class="period-range-display" v-else-if="periodDisplayLabel">
        {{ periodDisplayLabel }}
      </div>
    </div>

    <div v-if="loading && !data" class="wallet-loading">
      <i class="fas fa-spinner fa-spin"></i>
      <p>Loading…</p>
    </div>

    <div v-else-if="data">
      <!-- Period vs lifetime totals -->
      <div class="wallet-stats-grid">
        <div class="wallet-stat-card">
          <div class="stat-header">
            <div class="stat-icon info">
              <i class="fas fa-calendar-check"></i>
            </div>
          </div>
          <div class="stat-label">{{ __wt('staffDetailPeriod') }}</div>
          <div class="stat-value">฿{{ formatNumber(data.periodTotals.totalCharged) }}</div>
          <div class="stat-subtitle">
            {{ formatInt(data.periodTotals.txCount) }} {{ __wt('staffCol_transactions').toLowerCase() }}
          </div>
        </div>
        <div class="wallet-stat-card">
          <div class="stat-header">
            <div class="stat-icon success">
              <i class="fas fa-infinity"></i>
            </div>
          </div>
          <div class="stat-label">{{ __wt('staffDetailLifetime') }}</div>
          <div class="stat-value">฿{{ formatNumber(data.lifetimeTotals.totalCharged) }}</div>
          <div class="stat-subtitle">
            {{ formatInt(data.lifetimeTotals.txCount) }} {{ __wt('staffCol_transactions').toLowerCase() }}
          </div>
        </div>
        <div class="wallet-stat-card">
          <div class="stat-header">
            <div class="stat-icon info">
              <i class="fas fa-history"></i>
            </div>
          </div>
          <div class="stat-label">{{ __wt('staffDetailFirstActive') }}</div>
          <div class="stat-value-small">
            {{ data.lifetimeTotals.firstActivity ? formatDate(data.lifetimeTotals.firstActivity) : '—' }}
          </div>
        </div>
        <div class="wallet-stat-card">
          <div class="stat-header">
            <div class="stat-icon warning">
              <i class="fas fa-clock"></i>
            </div>
          </div>
          <div class="stat-label">{{ __wt('staffDetailLastActive') }}</div>
          <div class="stat-value-small">
            {{ data.lifetimeTotals.lastActivity ? formatDate(data.lifetimeTotals.lastActivity) : '—' }}
          </div>
        </div>
      </div>

      <!-- Per-branch breakdown -->
      <div class="staff-branch-card" v-if="data.branchBreakdown && data.branchBreakdown.length">
        <h2>
          <i class="fas fa-map-marker-alt"></i>
          {{ __wt('staffBranchBreakdownTitle') }}
          <span class="staff-tx-count">{{ formatInt(data.branchBreakdown.length) }}</span>
        </h2>
        <table class="staff-branch-table">
          <thead>
            <tr>
              <th>{{ __wt('staffBranchCol_branch') }}</th>
              <th class="num">{{ __wt('staffBranchCol_transactions') }}</th>
              <th class="num">{{ __wt('staffBranchCol_totalCharged') }}</th>
              <th class="num">{{ __wt('staffBranchCol_share') }}</th>
              <th>{{ __wt('staffBranchCol_lastActivity') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="b in data.branchBreakdown"
              :key="b.branch"
              :class="{ 'branch-row-unattributed': b.unattributed }"
            >
              <td>
                <span v-if="b.unattributed" class="staff-tag-amber-inline">
                  <i class="fas fa-question-circle"></i> {{ b.branch }}
                </span>
                <span v-else>{{ b.branch }}</span>
              </td>
              <td class="num">{{ formatInt(b.txCount) }}</td>
              <td class="num"><strong>฿{{ formatNumber(b.totalCharged) }}</strong></td>
              <td class="num">{{ branchShareOfStaff(b.totalCharged) }}%</td>
              <td>{{ formatRelativeDate(b.lastActivity) }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Transactions table -->
      <div class="staff-tx-card">
        <h2>
          <i class="fas fa-list"></i>
          {{ __wt('staffDetailTxTitle') }}
          <span class="staff-tx-count">{{ formatInt(data.periodTotals.txCount) }}</span>
        </h2>

        <div v-if="data.transactions.length === 0" class="staff-tx-empty">
          {{ __wt('staffDetailTxEmpty') }}
        </div>

        <div v-else>
          <table class="staff-tx-table">
            <thead>
              <tr>
                <th>{{ __wt('staffDetailCol_date') }}</th>
                <th>{{ __wt('staffDetailCol_customer') }}</th>
                <th>{{ __wt('staffDetailCol_branch') }}</th>
                <th>{{ __wt('staffDetailCol_type') }}</th>
                <th class="num">{{ __wt('staffDetailCol_amount') }}</th>
                <th>{{ __wt('staffDetailCol_description') }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="t in data.transactions" :key="t.id">
                <td>
                  <div>{{ formatDate(t.createdAt) }}</div>
                  <code class="tx-id muted">{{ t.id }}</code>
                </td>
                <td>
                  <nuxt-link :to="`/wallets/${t.userId}`" class="customer-link">
                    {{ t.customerName }}
                  </nuxt-link>
                </td>
                <td>{{ t.branch || '—' }}</td>
                <td>
                  <span :class="['type-pill', `type-${t.type}`]">
                    {{ formatType(t.type) }}
                  </span>
                </td>
                <td class="num"><strong>฿{{ formatNumber(t.amount) }}</strong></td>
                <td class="desc-cell">{{ t.description || '—' }}</td>
              </tr>
            </tbody>
          </table>

          <div class="staff-tx-pagination">
            <button
              class="wallet-btn secondary"
              :disabled="offset === 0 || loading"
              @click="prevPage"
            >
              <i class="fas fa-chevron-left"></i>
              Previous
            </button>
            <span class="page-label">
              Showing {{ offset + 1 }} – {{ offset + data.transactions.length }}
            </span>
            <button
              class="wallet-btn secondary"
              :disabled="!data.pagination.hasMore || loading"
              @click="nextPage"
            >
              Next
              <i class="fas fa-chevron-right"></i>
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-else class="staff-tx-empty">
      Staff not found.
    </div>
  </div>
</template>

<script>
import Breadcrumb from '~/components/Breadcrumb';

export default {
  name: 'StaffDetail',
  middleware: 'auth',
  components: { Breadcrumb },
  data() {
    return {
      loading: false,
      data: null,
      offset: 0,
      limit: 50,
      period: 'custom',
      customRange: { from: '', to: '' },
      periodOptions: [
        { key: 'today', i18n: 'periodToday' },
        { key: '7d', i18n: 'period7d' },
        { key: 'mtd', i18n: 'periodMtd' },
        { key: '30d', i18n: 'period30d' },
        { key: 'custom', i18n: 'periodCustom' },
      ],
    };
  },
  computed: {
    staffIdParam() {
      return this.$route.params.staffId;
    },
    staff() {
      return this.data?.staff;
    },
    breadcrumbs() {
      const label = this.staff?.fullName || this.staff?.username || `Staff #${this.staffIdParam}`;
      return [
        { label: 'Dashboard', path: '/dashboard' },
        { label: 'Wallet Management', path: '/wallets' },
        { label: 'Reports', path: '/wallets/reports' },
        { label: this.staff?.unattributed ? this.__wt('staffUnattributed') : label },
      ];
    },
    periodDisplayLabel() {
      const range = this.resolvePeriodRange();
      if (!range) return '';
      const from = this.$moment(range.from).tz('Asia/Bangkok');
      const to = this.$moment(range.to).tz('Asia/Bangkok');
      if (from.isSame(to, 'day')) return from.format('MMM D, YYYY');
      return `${from.format('MMM D')} – ${to.format('MMM D, YYYY')}`;
    },
  },
  async mounted() {
    this.__hydrateWalletUiLang();
    // Seed period state from the URL query (passed by the reports
    // page's drill-through). After this, the picker is the source of
    // truth — URL changes are pushed by the picker itself.
    const q = this.$route.query || {};
    if (q.fromDate && q.toDate) {
      this.period = 'custom';
      this.customRange = { from: q.fromDate, to: q.toDate };
    } else {
      this.period = 'mtd';
    }
    await this.load();
  },
  methods: {
    async load() {
      this.loading = true;
      try {
        const params = {
          limit: this.limit,
          offset: this.offset,
        };
        const range = this.resolvePeriodRange();
        if (range) {
          params.fromDate = range.from;
          params.toDate = range.to;
        }

        const response = await this.$walletService.getStaffTransactions(this.staffIdParam, params);
        if (response.success) {
          this.data = response.data;
        }
      } catch (e) {
        this.$swal({
          icon: 'error',
          title: 'Error',
          text: e.response?.data?.error?.message || 'Failed to load staff detail',
        });
      } finally {
        this.loading = false;
      }
    },

    resolvePeriodRange() {
      const now = this.$moment().tz('Asia/Bangkok');
      let from;
      let to;
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
      this.offset = 0;
      if (key !== 'custom') {
        this.load();
      }
    },

    applyCustomRange() {
      if (this.customRange.from && this.customRange.to) {
        this.offset = 0;
        this.load();
      }
    },

    branchShareOfStaff(amount) {
      const total = this.data?.periodTotals?.totalCharged || 0;
      if (!total) return '0.0';
      return ((amount / total) * 100).toFixed(1);
    },

    formatRelativeDate(date) {
      if (!date) return '—';
      return this.$moment(date).tz('Asia/Bangkok').fromNow();
    },

    prevPage() {
      if (this.offset === 0) return;
      this.offset = Math.max(0, this.offset - this.limit);
      this.load();
    },

    nextPage() {
      if (!this.data?.pagination?.hasMore) return;
      this.offset += this.limit;
      this.load();
    },

    toggleWalletLang() {
      const next = this.$store.state.walletUiLang === 'th' ? 'en' : 'th';
      this.__setWalletUiLang(next);
    },

    formatNumber(v) {
      if (v == null) return '0.00';
      return parseFloat(v).toLocaleString('en-US', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      });
    },
    formatInt(v) {
      if (v == null) return '0';
      return parseInt(v, 10).toLocaleString('en-US');
    },
    formatDate(date) {
      if (!date) return '—';
      return this.$moment(date).tz('Asia/Bangkok').format('MMM D, YYYY HH:mm');
    },
    formatType(type) {
      const map = {
        store_payment: 'Store',
        beer_machine_payment: 'Beer Machine',
      };
      return map[type] || type;
    },
  },
};
</script>

<style scoped>
.staff-id-chip {
  margin-left: 8px;
  font-family: 'SF Mono', Menlo, Consolas, monospace;
  font-size: 12px;
  color: #6B7280;
  background: #F1F5F9;
  padding: 2px 8px;
  border-radius: 6px;
}

.stat-value-small {
  font-size: 15px;
  font-weight: 600;
  color: #063F48;
}

.staff-tx-card {
  background: #fff;
  border-radius: 16px;
  padding: 24px;
  border: 1px solid #E2E8F0;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
}

.staff-tx-card h2 {
  margin: 0 0 16px;
  font-size: 18px;
  color: #063F48;
}

.staff-tx-card h2 i {
  margin-right: 8px;
  color: #1797AD;
}

.staff-tx-count {
  display: inline-block;
  margin-left: 8px;
  padding: 2px 10px;
  font-size: 12px;
  font-weight: 600;
  background: #F1F5F9;
  color: #4B5563;
  border-radius: 999px;
  vertical-align: middle;
}

.staff-tx-empty {
  padding: 40px 20px;
  text-align: center;
  color: #9CA3AF;
}

.staff-tx-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  font-variant-numeric: tabular-nums;
}

.staff-tx-table thead th {
  text-align: left;
  padding: 10px 12px;
  background: #F7FAFC;
  font-weight: 600;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: #6B7280;
  border-bottom: 1px solid #E5E7EB;
}

.staff-tx-table th.num,
.staff-tx-table td.num { text-align: right; }

.staff-tx-table tbody td {
  padding: 12px;
  border-bottom: 1px solid #F1F5F9;
  color: #1F2937;
  vertical-align: top;
}

.staff-tx-table tbody tr:hover td { background: #F9FAFB; }

.tx-id {
  font-family: 'SF Mono', Menlo, Consolas, monospace;
  font-size: 10px;
}

.tx-id.muted {
  color: #9CA3AF;
  margin-top: 2px;
  display: inline-block;
}

.customer-link {
  color: #1797AD;
  font-weight: 600;
  text-decoration: none;
}
.customer-link:hover { text-decoration: underline; }

.type-pill {
  display: inline-block;
  padding: 2px 10px;
  font-size: 11px;
  font-weight: 600;
  border-radius: 999px;
  background: #F1F5F9;
  color: #4B5563;
}

.type-pill.type-beer_machine_payment {
  background: rgba(245, 158, 11, 0.15);
  color: #92400E;
}

.type-pill.type-store_payment {
  background: rgba(23, 151, 173, 0.15);
  color: #1797AD;
}

.desc-cell {
  max-width: 280px;
  color: #6B7280;
  font-size: 12px;
}

.staff-tx-pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  margin-top: 20px;
}

.page-label {
  font-size: 13px;
  color: #6B7280;
}

.wallet-lang-toggle {
  font-weight: 600;
  letter-spacing: 0.02em;
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
}
.period-btn:hover { background: rgba(23, 151, 173, 0.08); }
.period-btn.active { background: #1797AD; color: #fff; }

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

.staff-branch-card {
  background: #fff;
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 24px;
  border: 1px solid #E2E8F0;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
}
.staff-branch-card h2 {
  margin: 0 0 16px;
  font-size: 18px;
  color: #063F48;
}
.staff-branch-card h2 i {
  margin-right: 8px;
  color: #1797AD;
}

.staff-branch-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  font-variant-numeric: tabular-nums;
}
.staff-branch-table thead th {
  text-align: left;
  padding: 10px 12px;
  background: #F7FAFC;
  font-weight: 600;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: #6B7280;
  border-bottom: 1px solid #E5E7EB;
}
.staff-branch-table th.num,
.staff-branch-table td.num { text-align: right; }
.staff-branch-table tbody td {
  padding: 10px 12px;
  border-bottom: 1px solid #F1F5F9;
  color: #1F2937;
}
.staff-branch-table tbody tr:last-child td { border-bottom: none; }
.staff-branch-table tbody tr:hover td { background: #F9FAFB; }

.branch-row-unattributed {
  background: rgba(245, 158, 11, 0.04);
}
.branch-row-unattributed:hover td { background: rgba(245, 158, 11, 0.1); }

.staff-tag-amber-inline {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-weight: 600;
  color: #92400E;
}
.staff-tag-amber-inline i { color: #F59E0B; }
</style>
