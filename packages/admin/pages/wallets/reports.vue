<template>
  <div class="wallet-page-container">
    <Breadcrumb :items="breadcrumbs" />

    <!-- Page Header -->
    <div class="wallet-page-header">
      <div>
        <h1>Financial Reports & Analytics</h1>
        <p class="subtitle">Comprehensive wallet and transaction analytics</p>
      </div>
      <div class="header-actions">
        <button @click="exportReport" class="wallet-btn success">
          <i class="fas fa-download"></i>
          Export Report
        </button>
        <button @click="loadReports" class="wallet-btn primary">
          <i class="fas fa-sync-alt"></i>
          Refresh
        </button>
      </div>
    </div>

    <!-- Date Range Filters -->
    <div class="wallet-filters-panel">
      <div class="wallet-filters-grid">
        <div class="wallet-filter-item">
          <label>
            <i class="fas fa-calendar-alt"></i>
            From Date
          </label>
          <input v-model="filters.fromDate" type="date" />
        </div>
        <div class="wallet-filter-item">
          <label>
            <i class="fas fa-calendar-check"></i>
            To Date
          </label>
          <input v-model="filters.toDate" type="date" />
        </div>
        <div class="wallet-filter-item">
          <label>
            <i class="fas fa-chart-bar"></i>
            Report Type
          </label>
          <select v-model="filters.reportType">
            <option value="summary">Summary Report</option>
            <option value="detailed">Detailed Report</option>
          </select>
        </div>
        <div style="display: flex; align-items: flex-end;">
          <button @click="loadReports" class="wallet-btn primary" style="width: 100%;">
            <i class="fas fa-filter"></i>
            Apply Filters
          </button>
        </div>
      </div>
    </div>

    <div v-if="loading" class="wallet-loading">
      <i class="fas fa-spinner fa-spin"></i>
      <p>Generating reports...</p>
    </div>

    <div v-else class="reports-content">
      <!-- Machine Revenue (beer machines, by branch) -->
      <div class="machine-revenue-card">
        <div class="machine-revenue-header">
          <div>
            <h2>
              <i class="fas fa-beer"></i>
              Beer Machine Revenue
            </h2>
            <p>
              Revenue, pours, and volume dispensed per machine, grouped by branch.
            </p>
          </div>
          <div class="machine-revenue-totals">
            <div class="mrev-total">
              <span class="mrev-total-label">Revenue</span>
              <span class="mrev-total-value">฿{{ formatNumber(machineTotals.revenue) }}</span>
            </div>
            <div class="mrev-total">
              <span class="mrev-total-label">Pours</span>
              <span class="mrev-total-value">{{ formatInt(machineTotals.pours) }}</span>
            </div>
            <div class="mrev-total">
              <span class="mrev-total-label">Volume</span>
              <span class="mrev-total-value">{{ formatVolume(machineTotals.volumeMl) }}</span>
            </div>
          </div>
        </div>

        <div v-if="machineGroups.length === 0" class="mrev-empty">
          <i class="fas fa-beer"></i>
          <p>No beer machine activity in this period.</p>
        </div>

        <div v-else class="mrev-branch-groups">
          <div
            v-for="group in machineGroups"
            :key="group.branch"
            :class="['mrev-branch-group', { unattributed: group.branchUnattributed }]"
          >
            <div class="mrev-branch-head">
              <div class="mrev-branch-title">
                <i v-if="group.branchUnattributed" class="fas fa-question-circle"></i>
                <i v-else class="fas fa-map-marker-alt"></i>
                {{ group.branch }}
                <span v-if="group.branchUnattributed" class="mrev-tag">no branch</span>
              </div>
              <div class="mrev-branch-summary">
                <span><strong>฿{{ formatNumber(group.revenue) }}</strong></span>
                <span class="muted">·</span>
                <span>{{ formatInt(group.pours) }} pours</span>
                <span class="muted">·</span>
                <span>{{ formatVolume(group.volumeMl) }}</span>
                <span class="muted">·</span>
                <span>{{ branchShareOfTotal(group.revenue) }}%</span>
              </div>
            </div>

            <table class="mrev-table">
              <thead>
                <tr>
                  <th>Machine</th>
                  <th class="num">Pours</th>
                  <th class="num">Volume</th>
                  <th class="num">Revenue</th>
                  <th class="num">Avg / pour</th>
                  <th class="num">% of branch</th>
                  <th>Last activity</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="m in group.machines"
                  :key="`${group.branch}-${m.machineId || 'unknown'}`"
                  :class="{ 'mrev-unknown': m.machineUnknown }"
                >
                  <td>
                    <code class="machine-id" v-if="m.machineId">{{ m.machineId }}</code>
                    <span v-else class="mrev-tag">unknown machine</span>
                  </td>
                  <td class="num">{{ formatInt(m.pours) }}</td>
                  <td class="num">{{ formatVolume(m.volumeMl) }}</td>
                  <td class="num"><strong>฿{{ formatNumber(m.revenue) }}</strong></td>
                  <td class="num">฿{{ formatNumber(m.pours ? m.revenue / m.pours : 0) }}</td>
                  <td class="num">{{ machineShareOfBranch(m.revenue, group.revenue) }}%</td>
                  <td>{{ formatRelativeDate(m.lastActivity) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Summary Cards -->
      <div class="wallet-stats-grid">
        <div class="wallet-stat-card">
          <div class="stat-header">
            <div class="stat-icon info">
              <i class="fas fa-wallet"></i>
            </div>
          </div>
          <div class="stat-label">Total Wallet Balance</div>
          <div class="stat-value">฿{{ formatNumber(report.summary?.totalWalletBalance) }}</div>
          <div class="stat-subtitle">Pending: ฿{{ formatNumber(report.summary?.totalPendingBalance) }}</div>
        </div>

        <div class="wallet-stat-card">
          <div class="stat-header">
            <div class="stat-icon success">
              <i class="fas fa-users"></i>
            </div>
          </div>
          <div class="stat-label">Active Wallets</div>
          <div class="stat-value">{{ formatNumber(report.summary?.activeWallets) }}</div>
          <div class="stat-subtitle">Frozen: {{ report.summary?.frozenWallets || 0 }}</div>
        </div>

        <div class="wallet-stat-card">
          <div class="stat-header">
            <div class="stat-icon info">
              <i class="fas fa-exchange-alt"></i>
            </div>
          </div>
          <div class="stat-label">Total Transactions</div>
          <div class="stat-value">{{ formatNumber(report.transactionSummary?.totalTransactions) }}</div>
          <div class="stat-subtitle">Volume: ฿{{ formatNumber(report.transactionSummary?.totalVolume) }}</div>
        </div>

        <div class="wallet-stat-card">
          <div class="stat-header">
            <div class="stat-icon success">
              <i class="fas fa-coins"></i>
            </div>
          </div>
          <div class="stat-label">Revenue</div>
          <div class="stat-value">฿{{ formatNumber(report.revenue?.totalRevenue) }}</div>
          <div class="stat-subtitle">From transaction fees</div>
        </div>
      </div>

      <!-- Transaction Breakdown -->
      <div style="background: white; border-radius: 16px; padding: 24px; margin-bottom: 24px; border: 1px solid #E2E8F0; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);">
        <h2 style="font-size: 20px; font-weight: 700; color: #063F48; margin-bottom: 24px;">
          <i class="fas fa-chart-pie"></i>
          Transaction Breakdown by Type
        </h2>
        <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 16px;">
          <div
            v-for="(data, type) in report.transactionSummary?.byType"
            :key="type"
            style="background: #F7FAFC; border-radius: 12px; padding: 20px; text-align: center; border: 1px solid #E2E8F0;"
          >
            <div style="font-size: 14px; font-weight: 600; color: #4A5568; margin-bottom: 8px; text-transform: capitalize;">
              {{ formatType(type) }}
            </div>
            <div style="font-size: 12px; color: #6B7280; margin-bottom: 8px;">
              {{ data.count }} transactions
            </div>
            <div style="font-size: 22px; font-weight: 700; color: #1797AD;">
              ฿{{ formatNumber(data.volume) }}
            </div>
          </div>
        </div>
      </div>

      <!-- Charts Section -->
      <div class="charts-grid">
        <div class="wallet-stat-card chart-card">
          <h3 class="chart-title">
            <i class="fas fa-chart-bar"></i>
            Volume by Transaction Type
          </h3>
          <div v-if="!hasTypeData" class="chart-empty">
            <i class="fas fa-chart-bar"></i>
            <p>No transactions in this period</p>
          </div>
          <div v-else class="chart-canvas-wrap">
            <canvas ref="volumeChart"></canvas>
          </div>
        </div>

        <div class="wallet-stat-card chart-card">
          <h3 class="chart-title">
            <i class="fas fa-chart-pie"></i>
            Transactions by Type
          </h3>
          <div v-if="!hasTypeData" class="chart-empty">
            <i class="fas fa-chart-pie"></i>
            <p>No transactions in this period</p>
          </div>
          <div v-else class="chart-canvas-wrap">
            <canvas ref="countChart"></canvas>
          </div>
        </div>
      </div>

      <!-- Detailed Stats Table -->
      <div class="wallet-table-container">
        <h2 style="font-size: 20px; font-weight: 700; color: #063F48; margin-bottom: 20px; padding: 0 16px; padding-top: 16px;">
          <i class="fas fa-table"></i>
          Detailed Statistics
        </h2>
        <table class="wallet-table">
          <thead>
            <tr>
              <th><i class="fas fa-tag"></i> Metric</th>
              <th style="text-align: right;"><i class="fas fa-chart-bar"></i> Value</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Total Wallet Balance</td>
              <td style="text-align: right; font-weight: 600; color: #1797AD;">฿{{ formatNumber(report.summary?.totalWalletBalance) }}</td>
            </tr>
            <tr>
              <td>Total Pending Balance</td>
              <td style="text-align: right; font-weight: 600; color: #FFB800;">฿{{ formatNumber(report.summary?.totalPendingBalance) }}</td>
            </tr>
            <tr>
              <td>Total Frozen Balance</td>
              <td style="text-align: right; font-weight: 600; color: #6B7280;">฿{{ formatNumber(report.summary?.totalFrozenBalance) }}</td>
            </tr>
            <tr>
              <td>Active Wallets</td>
              <td style="text-align: right; font-weight: 600;">{{ report.summary?.activeWallets }}</td>
            </tr>
            <tr>
              <td>Frozen Wallets</td>
              <td style="text-align: right; font-weight: 600;">{{ report.summary?.frozenWallets }}</td>
            </tr>
            <tr>
              <td>Suspended Wallets</td>
              <td style="text-align: right; font-weight: 600;">{{ report.summary?.suspendedWallets }}</td>
            </tr>
            <tr>
              <td>Total Transactions</td>
              <td style="text-align: right; font-weight: 600;">{{ formatNumber(report.transactionSummary?.totalTransactions) }}</td>
            </tr>
            <tr>
              <td>Total Transaction Volume</td>
              <td style="text-align: right; font-weight: 600; color: #1797AD;">฿{{ formatNumber(report.transactionSummary?.totalVolume) }}</td>
            </tr>
            <tr>
              <td>Top-up Fees Revenue</td>
              <td style="text-align: right; font-weight: 600; color: #00A862;">฿{{ formatNumber(report.revenue?.topUpFees) }}</td>
            </tr>
            <tr>
              <td>Total Revenue</td>
              <td style="text-align: right; font-weight: 700; color: #00A862; font-size: 16px;">฿{{ formatNumber(report.revenue?.totalRevenue) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script>
import Breadcrumb from '~/components/Breadcrumb';

export default {
  name: 'WalletReports',
  middleware: 'auth',
  components: {
    Breadcrumb,
  },
  data() {
    return {
      breadcrumbs: [
        { label: 'Dashboard', path: '/dashboard' },
        { label: 'Wallet Management', path: '/wallets' },
        { label: 'Reports' },
      ],
      loading: false,
      filters: {
        fromDate: this.$moment().subtract(30, 'days').format('YYYY-MM-DD'),
        toDate: this.$moment().format('YYYY-MM-DD'),
        reportType: 'summary',
      },
      report: {
        summary: {},
        transactionSummary: {},
        revenue: {},
        byMachine: [],
      },
      Chart: null,
      volumeChartInstance: null,
      countChartInstance: null,
    };
  },
  computed: {
    typeEntries() {
      const byType = this.report.transactionSummary?.byType || {};
      return Object.entries(byType).filter(([, d]) => (d.count || 0) > 0 || (d.volume || 0) > 0);
    },
    hasTypeData() {
      return this.typeEntries.length > 0;
    },
    // Re-group the flat byMachine array into per-branch buckets, each
    // carrying its own machines list and aggregate totals. Sorted so
    // the highest-grossing branch shows first.
    machineGroups() {
      const rows = this.report.byMachine || [];
      const groups = new Map();
      rows.forEach((row) => {
        const key = row.branch;
        if (!groups.has(key)) {
          groups.set(key, {
            branch: row.branch,
            branchUnattributed: row.branchUnattributed,
            machines: [],
            revenue: 0,
            pours: 0,
            volumeMl: 0,
          });
        }
        const g = groups.get(key);
        g.machines.push(row);
        g.revenue += row.revenue;
        g.pours += row.pours;
        g.volumeMl += row.volumeMl;
      });
      return Array.from(groups.values())
        .map((g) => ({
          ...g,
          machines: g.machines.slice().sort((a, b) => b.revenue - a.revenue),
        }))
        .sort((a, b) => b.revenue - a.revenue);
    },
    machineTotals() {
      return (this.report.byMachine || []).reduce(
        (acc, r) => ({
          revenue: acc.revenue + r.revenue,
          pours: acc.pours + r.pours,
          volumeMl: acc.volumeMl + r.volumeMl,
        }),
        { revenue: 0, pours: 0, volumeMl: 0 }
      );
    },
  },
  async mounted() {
    if (process.client) {
      const chartModule = await import('chart.js');
      this.Chart = chartModule.Chart;
    }
    await this.loadReports();
  },
  beforeDestroy() {
    this.destroyCharts();
  },
  methods: {
    async loadReports() {
      this.loading = true;
      try {
        const response = await this.$walletService.getReports(this.filters);

        if (response.success) {
          this.report = response.data;
          this.$nextTick(() => this.renderCharts());
        }
      } catch (error) {
        console.error('Error loading reports:', error);
        this.$swal({
          icon: 'error',
          title: 'Error',
          text: 'Failed to load reports',
        });
      } finally {
        this.loading = false;
      }
    },

    destroyCharts() {
      if (this.volumeChartInstance) {
        this.volumeChartInstance.destroy();
        this.volumeChartInstance = null;
      }
      if (this.countChartInstance) {
        this.countChartInstance.destroy();
        this.countChartInstance = null;
      }
    },

    renderCharts() {
      if (!this.Chart || !this.hasTypeData) return;
      this.destroyCharts();

      const labels = this.typeEntries.map(([type]) => this.formatType(type));
      const volumes = this.typeEntries.map(([, d]) => parseFloat(d.volume) || 0);
      const counts = this.typeEntries.map(([, d]) => parseInt(d.count, 10) || 0);

      const palette = [
        '#1797AD', '#00A862', '#FFB800', '#E45858',
        '#7C5CFF', '#FF8A4C', '#3FB6E0', '#9E7BFF',
      ];
      const colors = labels.map((_, i) => palette[i % palette.length]);

      const volumeCanvas = this.$refs.volumeChart;
      if (volumeCanvas) {
        this.volumeChartInstance = new this.Chart(volumeCanvas, {
          type: 'bar',
          data: {
            labels,
            datasets: [{
              label: 'Volume (฿)',
              data: volumes,
              backgroundColor: colors,
              borderRadius: 6,
            }],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
              legend: { display: false },
              tooltip: {
                callbacks: {
                  label: (ctx) => `฿${ctx.parsed.y.toLocaleString('en-US', {
                    minimumFractionDigits: 2, maximumFractionDigits: 2,
                  })}`,
                },
              },
            },
            scales: {
              y: {
                beginAtZero: true,
                ticks: {
                  callback: (v) => `฿${Number(v).toLocaleString('en-US')}`,
                },
              },
            },
          },
        });
      }

      const countCanvas = this.$refs.countChart;
      if (countCanvas) {
        this.countChartInstance = new this.Chart(countCanvas, {
          type: 'doughnut',
          data: {
            labels,
            datasets: [{ data: counts, backgroundColor: colors, borderWidth: 0 }],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '60%',
            plugins: {
              legend: { position: 'bottom', labels: { boxWidth: 12, padding: 12 } },
              tooltip: {
                callbacks: {
                  label: (ctx) => {
                    const total = counts.reduce((a, b) => a + b, 0) || 1;
                    const pct = ((ctx.parsed / total) * 100).toFixed(1);
                    return `${ctx.label}: ${ctx.parsed} (${pct}%)`;
                  },
                },
              },
            },
          },
        });
      }
    },

    async exportReport() {
      try {
        const csvData = this.generateReportCSV();
        const filename = `wallet-report-${this.filters.fromDate}-to-${this.filters.toDate}.csv`;
        this.$walletService.downloadCSV(csvData, filename);
      } catch (error) {
        console.error('Error exporting report:', error);
        this.$swal({
          icon: 'error',
          title: 'Error',
          text: 'Failed to export report',
        });
      }
    },

    generateReportCSV() {
      const rows = [];

      rows.push(['Wallet Financial Report']);
      rows.push([`Period: ${this.filters.fromDate} to ${this.filters.toDate}`]);
      rows.push([]);

      rows.push(['SUMMARY']);
      rows.push(['Total Wallet Balance', this.report.summary?.totalWalletBalance || 0]);
      rows.push(['Active Wallets', this.report.summary?.activeWallets || 0]);
      rows.push(['Total Transactions', this.report.transactionSummary?.totalTransactions || 0]);
      rows.push(['Total Revenue', this.report.revenue?.totalRevenue || 0]);
      rows.push([]);

      rows.push(['TRANSACTION BREAKDOWN']);
      rows.push(['Type', 'Count', 'Volume']);
      for (const [type, data] of Object.entries(this.report.transactionSummary?.byType || {})) {
        rows.push([type, data.count, data.volume]);
      }
      rows.push([]);

      rows.push(['BEER MACHINE REVENUE']);
      rows.push(['Branch', 'Machine ID', 'Pours', 'Volume (ml)', 'Revenue', 'Avg per pour', 'Last activity']);
      for (const m of this.report.byMachine || []) {
        const avg = m.pours ? m.revenue / m.pours : 0;
        const last = m.lastActivity
          ? this.$moment(m.lastActivity).tz('Asia/Bangkok').format('YYYY-MM-DD HH:mm')
          : '';
        rows.push([
          this.csvCell(m.branch),
          this.csvCell(m.machineId || 'unknown'),
          m.pours,
          Math.round(m.volumeMl),
          m.revenue.toFixed(2),
          avg.toFixed(2),
          last,
        ]);
      }

      return rows.map((row) => row.join(',')).join('\n');
    },

    csvCell(value) {
      const s = value === null || value === undefined ? '' : String(value);
      if (s.includes(',') || s.includes('"') || s.includes('\n')) {
        return `"${s.replace(/"/g, '""')}"`;
      }
      return s;
    },

    formatNumber(value) {
      if (value === null || value === undefined) return '0';
      return parseFloat(value).toLocaleString('en-US', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
      });
    },

    formatInt(value) {
      if (value === null || value === undefined) return '0';
      return parseInt(value, 10).toLocaleString('en-US');
    },

    // Pours are stored in millilitres. Show ml under 1L and L above.
    formatVolume(ml) {
      const n = parseFloat(ml) || 0;
      if (n >= 1000) {
        return `${(n / 1000).toLocaleString('en-US', {
          minimumFractionDigits: 1,
          maximumFractionDigits: 2,
        })} L`;
      }
      return `${Math.round(n).toLocaleString('en-US')} ml`;
    },

    formatRelativeDate(date) {
      if (!date) return '—';
      return this.$moment(date).tz('Asia/Bangkok').fromNow();
    },

    branchShareOfTotal(branchRevenue) {
      const total = this.machineTotals.revenue;
      if (!total) return '0.0';
      return ((branchRevenue / total) * 100).toFixed(1);
    },

    machineShareOfBranch(machineRevenue, branchRevenue) {
      if (!branchRevenue) return '0.0';
      return ((machineRevenue / branchRevenue) * 100).toFixed(1);
    },

    formatType(type) {
      return type
        .split('_')
        .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');
    },
  },
};
</script>

<style scoped>
.reports-content {
  animation: fadeIn 0.3s ease;
}

.charts-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 24px;
  margin-bottom: 24px;
}

.chart-card {
  min-height: 340px;
  display: flex;
  flex-direction: column;
}

.chart-title {
  font-size: 18px;
  font-weight: 700;
  color: #063F48;
  margin-bottom: 16px;
}

.chart-canvas-wrap {
  flex: 1;
  position: relative;
  min-height: 260px;
}

.chart-empty {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: #F7FAFC;
  border: 2px dashed #E2E8F0;
  border-radius: 12px;
  padding: 40px;
  text-align: center;
  color: #6B7280;
}

.chart-empty i {
  font-size: 40px;
  color: #D1D5DB;
  margin-bottom: 12px;
}

.chart-empty p {
  margin: 0;
  font-size: 14px;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Machine Revenue card */
.machine-revenue-card {
  background: #fff;
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 24px;
  border: 1px solid #E2E8F0;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
}

.machine-revenue-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20px;
  gap: 24px;
  flex-wrap: wrap;
}

.machine-revenue-header h2 {
  margin: 0 0 4px;
  font-size: 20px;
  font-weight: 700;
  color: #063F48;
}

.machine-revenue-header h2 i {
  margin-right: 8px;
  color: #F59E0B;
}

.machine-revenue-header p {
  margin: 0;
  font-size: 13px;
  color: #6B7280;
}

.machine-revenue-totals {
  display: flex;
  gap: 24px;
  flex-wrap: wrap;
}

.mrev-total {
  text-align: right;
}

.mrev-total-label {
  display: block;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #6B7280;
}

.mrev-total-value {
  display: block;
  font-size: 18px;
  font-weight: 700;
  color: #1797AD;
}

.mrev-empty {
  padding: 48px 20px;
  text-align: center;
  color: #6B7280;
}

.mrev-empty i {
  font-size: 32px;
  display: block;
  margin-bottom: 8px;
  color: #D1D5DB;
}

.mrev-empty p {
  margin: 0;
  font-size: 14px;
}

.mrev-branch-groups {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.mrev-branch-group {
  border: 1px solid #E5E7EB;
  border-radius: 12px;
  overflow: hidden;
}

.mrev-branch-group.unattributed {
  border-color: rgba(245, 158, 11, 0.45);
  background: rgba(245, 158, 11, 0.04);
}

.mrev-branch-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 14px 18px;
  background: #F9FAFB;
  border-bottom: 1px solid #E5E7EB;
  flex-wrap: wrap;
  gap: 12px;
}

.mrev-branch-group.unattributed .mrev-branch-head {
  background: rgba(245, 158, 11, 0.08);
}

.mrev-branch-title {
  font-size: 15px;
  font-weight: 700;
  color: #063F48;
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.mrev-branch-title i {
  color: #1797AD;
}

.mrev-branch-group.unattributed .mrev-branch-title i {
  color: #92400E;
}

.mrev-branch-summary {
  font-size: 13px;
  color: #4B5563;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.mrev-branch-summary strong {
  color: #1797AD;
  font-size: 14px;
}

.mrev-branch-summary .muted {
  color: #D1D5DB;
}

.mrev-tag {
  display: inline-block;
  margin-left: 8px;
  padding: 2px 8px;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #92400E;
  background: rgba(245, 158, 11, 0.18);
  border-radius: 999px;
  vertical-align: middle;
}

.mrev-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.mrev-table thead th {
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

.mrev-table th.num,
.mrev-table td.num {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

.mrev-table tbody td {
  padding: 12px;
  border-bottom: 1px solid #F1F5F9;
  color: #1F2937;
}

.mrev-table tbody tr:last-child td {
  border-bottom: none;
}

.mrev-table tbody tr:hover td {
  background: #F9FAFB;
}

.mrev-table tr.mrev-unknown td {
  background: rgba(245, 158, 11, 0.04);
}

.machine-id {
  font-family: 'SF Mono', Menlo, Consolas, monospace;
  font-size: 12px;
  padding: 2px 8px;
  background: #F1F5F9;
  border-radius: 6px;
  color: #0F172A;
}

@media (max-width: 768px) {
  .machine-revenue-header {
    flex-direction: column;
  }

  .machine-revenue-totals {
    width: 100%;
    justify-content: space-between;
  }

  .mrev-total {
    text-align: left;
  }

  .mrev-branch-summary {
    flex-wrap: wrap;
  }

  .mrev-table {
    font-size: 12px;
  }

  .mrev-table thead th,
  .mrev-table tbody td {
    padding: 8px;
  }
}
</style>
