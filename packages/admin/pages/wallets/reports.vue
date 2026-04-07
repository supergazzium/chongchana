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
      <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 24px; margin-bottom: 24px;">
        <div class="wallet-stat-card" style="min-height: 300px; display: flex; flex-direction: column;">
          <h3 style="font-size: 18px; font-weight: 700; color: #063F48; margin-bottom: 16px;">
            <i class="fas fa-chart-line"></i>
            Transaction Volume Trend
          </h3>
          <div style="flex: 1; display: flex; align-items: center; justify-content: center; background: #F7FAFC; border: 2px dashed #E2E8F0; border-radius: 12px; padding: 40px; text-align: center;">
            <div>
              <i class="fas fa-chart-area" style="font-size: 48px; color: #D1D5DB; margin-bottom: 16px;"></i>
              <p style="color: #6B7280; font-size: 14px; margin: 0;">Chart visualization would go here</p>
              <p style="color: #9CA3AF; font-size: 12px; margin-top: 8px; font-style: italic;">
                Integrate Chart.js or similar library
              </p>
            </div>
          </div>
        </div>

        <div class="wallet-stat-card" style="min-height: 300px; display: flex; flex-direction: column;">
          <h3 style="font-size: 18px; font-weight: 700; color: #063F48; margin-bottom: 16px;">
            <i class="fas fa-chart-pie"></i>
            Transaction Types Distribution
          </h3>
          <div style="flex: 1; display: flex; align-items: center; justify-content: center; background: #F7FAFC; border: 2px dashed #E2E8F0; border-radius: 12px; padding: 40px; text-align: center;">
            <div>
              <i class="fas fa-chart-pie" style="font-size: 48px; color: #D1D5DB; margin-bottom: 16px;"></i>
              <p style="color: #6B7280; font-size: 14px; margin: 0;">Pie chart would go here</p>
              <p style="color: #9CA3AF; font-size: 12px; margin-top: 8px; font-style: italic;">
                Show percentage breakdown of types
              </p>
            </div>
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
      },
    };
  },
  async mounted() {
    await this.loadReports();
  },
  methods: {
    async loadReports() {
      this.loading = true;
      try {
        const response = await this.$walletService.getReports(this.filters);

        if (response.success) {
          this.report = response.data;
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

      return rows.map((row) => row.join(',')).join('\n');
    },

    formatNumber(value) {
      if (value === null || value === undefined) return '0';
      return parseFloat(value).toLocaleString('en-US', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
      });
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
</style>
