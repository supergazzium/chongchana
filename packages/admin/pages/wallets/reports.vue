<template>
  <div class="wallet-page-container">
    <Breadcrumb :items="breadcrumbs" />
    <WalletSubnav />

    <!-- Page Header -->
    <div class="wallet-page-header">
      <div>
        <h1>{{ __wt('rptTitle') }}</h1>
        <p class="subtitle">{{ __wt('rptSubtitle') }}</p>
      </div>
      <div class="header-actions no-print">
        <button
          @click="toggleWalletLang"
          class="wallet-btn secondary wallet-lang-toggle"
          :title="__wt('langToggle')"
        >
          <i class="fas fa-language"></i>
          {{ __wt('langToggle') }}
        </button>
        <button @click="printReport" class="wallet-btn secondary">
          <i class="fas fa-print"></i>
          {{ __wt('rptPrint') }}
        </button>
        <button @click="exportReport" class="wallet-btn success">
          <i class="fas fa-download"></i>
          {{ __wt('rptExportCsv') }}
        </button>
        <button @click="loadReports" class="wallet-btn primary">
          <i class="fas fa-sync-alt"></i>
          {{ __wt('rptRefresh') }}
        </button>
      </div>
    </div>

    <!-- Date Range Filters -->
    <div class="wallet-filters-panel no-print">
      <div class="wallet-filters-grid">
        <div class="wallet-filter-item">
          <label>
            <i class="fas fa-calendar-alt"></i>
            {{ __wt('rptFromDate') }}
          </label>
          <input v-model="filters.fromDate" type="date" />
        </div>
        <div class="wallet-filter-item">
          <label>
            <i class="fas fa-calendar-check"></i>
            {{ __wt('rptToDate') }}
          </label>
          <input v-model="filters.toDate" type="date" />
        </div>
        <div class="wallet-filter-item">
          <label>
            <i class="fas fa-chart-bar"></i>
            {{ __wt('rptReportType') }}
          </label>
          <select v-model="filters.reportType">
            <option value="summary">{{ __wt('rptReportSummary') }}</option>
            <option value="detailed">{{ __wt('rptReportDetailed') }}</option>
          </select>
        </div>
        <div style="display: flex; align-items: flex-end;">
          <button @click="loadReports" class="wallet-btn primary" style="width: 100%;">
            <i class="fas fa-filter"></i>
            {{ __wt('rptApplyFilters') }}
          </button>
        </div>
      </div>
    </div>

    <div v-if="loading" class="wallet-loading">
      <i class="fas fa-spinner fa-spin"></i>
      <p>{{ __wt('rptGenerating') }}</p>
    </div>

    <div v-else class="reports-content">
      <!-- Print-only header. Hidden on screen, shown when printed. -->
      <div class="print-only print-header">
        <h1>{{ __wt('rptPrintHeader') }}</h1>
        <div class="print-period">
          {{ __wt('rptPrintPeriod') }}: {{ filters.fromDate }} → {{ filters.toDate }}
        </div>
        <div class="print-generated">
          {{ __wt('rptPrintGenerated') }} {{ generatedAt }}
        </div>
      </div>

      <!-- Wallet Liability Reconciliation -->
      <div class="recon-card" v-if="report.reconciliation">
        <div class="recon-header">
          <div>
            <h2>
              <i class="fas fa-balance-scale-right"></i>
              {{ __wt('reconTitle') }}
            </h2>
            <p>{{ __wt('reconSubtitle') }}</p>
          </div>
          <div
            :class="['recon-status', report.reconciliation.reconciled ? 'ok' : 'mismatch']"
          >
            <i :class="report.reconciliation.reconciled ? 'fas fa-check-circle' : 'fas fa-exclamation-triangle'"></i>
            <span v-if="report.reconciliation.reconciled">{{ __wt('reconReconciled') }}</span>
            <span v-else>{{ __wt('reconMismatch', { amount: formatNumber(Math.abs(report.reconciliation.gap)) }) }}</span>
          </div>
        </div>

        <div class="recon-statement">
          <div class="recon-row recon-opening">
            <span class="recon-label">{{ __wt('reconOpeningBalance') }}</span>
            <span class="recon-sub">{{ formatStatementDate(report.period.from) }}</span>
            <span class="recon-amount">฿{{ formatNumber(report.reconciliation.openingBalance) }}</span>
          </div>

          <div class="recon-section-head">
            <i class="fas fa-plus-circle"></i> {{ __wt('reconCreditsHead') }}
          </div>
          <div
            v-for="line in nonZeroCredits"
            :key="line.key"
            class="recon-row recon-credit"
          >
            <span class="recon-label">{{ translateReconLine(line) }}</span>
            <span class="recon-sub">{{ __wt(line.count === 1 ? 'reconTransactionCountSingular' : 'reconTransactionCount', { count: line.count }) }}</span>
            <span class="recon-amount">+฿{{ formatNumber(line.amount) }}</span>
          </div>
          <div v-if="nonZeroCredits.length === 0" class="recon-row recon-empty">
            <span class="recon-label">{{ __wt('reconNoCredits') }}</span>
            <span class="recon-amount muted">฿0.00</span>
          </div>
          <div class="recon-row recon-subtotal">
            <span class="recon-label">{{ __wt('reconTotalCredits') }}</span>
            <span class="recon-amount">+฿{{ formatNumber(totalCredits) }}</span>
          </div>

          <div class="recon-section-head">
            <i class="fas fa-minus-circle"></i> {{ __wt('reconDebitsHead') }}
          </div>
          <div
            v-for="line in nonZeroDebits"
            :key="line.key"
            class="recon-row recon-debit"
          >
            <span class="recon-label">{{ translateReconLine(line) }}</span>
            <span class="recon-sub">{{ __wt(line.count === 1 ? 'reconTransactionCountSingular' : 'reconTransactionCount', { count: line.count }) }}</span>
            <span class="recon-amount">−฿{{ formatNumber(line.amount) }}</span>
          </div>
          <div v-if="nonZeroDebits.length === 0" class="recon-row recon-empty">
            <span class="recon-label">{{ __wt('reconNoDebits') }}</span>
            <span class="recon-amount muted">฿0.00</span>
          </div>
          <div class="recon-row recon-subtotal">
            <span class="recon-label">{{ __wt('reconTotalDebits') }}</span>
            <span class="recon-amount">−฿{{ formatNumber(totalDebits) }}</span>
          </div>

          <div class="recon-row recon-net">
            <span class="recon-label">{{ __wt('reconNetChange') }}</span>
            <span :class="['recon-amount', report.reconciliation.netChange >= 0 ? 'up' : 'down']">
              {{ report.reconciliation.netChange >= 0 ? '+' : '−' }}฿{{ formatNumber(Math.abs(report.reconciliation.netChange)) }}
            </span>
          </div>

          <div class="recon-row recon-closing">
            <span class="recon-label">{{ __wt('reconComputedClosing') }}</span>
            <span class="recon-sub">{{ __wt('reconComputedClosingSub') }}</span>
            <span class="recon-amount">฿{{ formatNumber(report.reconciliation.computedClosingBalance) }}</span>
          </div>

          <div class="recon-row recon-actual">
            <span class="recon-label">{{ __wt('reconActualClosing') }}</span>
            <span class="recon-sub">{{ __wt('reconActualClosingSub') }}</span>
            <span class="recon-amount">฿{{ formatNumber(report.reconciliation.actualClosingBalance) }}</span>
          </div>

          <div
            v-if="!report.reconciliation.reconciled"
            class="recon-row recon-gap"
          >
            <span class="recon-label">
              <i class="fas fa-exclamation-triangle"></i>
              {{ __wt('reconUnexplainedGap') }}
            </span>
            <span class="recon-sub">{{ __wt('reconUnexplainedGapSub') }}</span>
            <span class="recon-amount">฿{{ formatNumber(report.reconciliation.gap) }}</span>
          </div>
        </div>

        <div class="recon-footnote">
          <i class="fas fa-info-circle"></i>
          {{ __wt('reconFootnote') }}
        </div>
      </div>

      <!-- Cash Position -->
      <div class="cash-card" v-if="report.cashPosition">
        <div class="cash-header">
          <div>
            <h2>
              <i class="fas fa-coins"></i>
              {{ __wt('cashTitle') }}
            </h2>
            <p>{{ __wt('cashSubtitle') }}</p>
          </div>
          <div
            :class="['cash-net-pill', report.cashPosition.netCashPosition >= 0 ? 'up' : 'down']"
          >
            <span class="cash-net-label">{{ __wt('cashNetLabel') }}</span>
            <span class="cash-net-amount">
              {{ report.cashPosition.netCashPosition >= 0 ? '+' : '−' }}฿{{ formatNumber(Math.abs(report.cashPosition.netCashPosition)) }}
            </span>
          </div>
        </div>

        <div class="cash-tiles">
          <div class="cash-tile cash-tile-in">
            <div class="cash-tile-icon">
              <i class="fas fa-arrow-down"></i>
            </div>
            <div class="cash-tile-body">
              <div class="cash-tile-label">{{ __wt('cashCollected') }}</div>
              <div class="cash-tile-value">฿{{ formatNumber(report.cashPosition.cashCollected) }}</div>
              <div class="cash-tile-sub">{{ __wt('cashCollectedSub', { count: formatInt(report.cashPosition.cashCollectedCount) }) }}</div>
            </div>
          </div>

          <div class="cash-tile cash-tile-out">
            <div class="cash-tile-icon">
              <i class="fas fa-arrow-up"></i>
            </div>
            <div class="cash-tile-body">
              <div class="cash-tile-label">{{ __wt('cashServiceDelivered') }}</div>
              <div class="cash-tile-value">฿{{ formatNumber(report.cashPosition.serviceDelivered) }}</div>
              <div class="cash-tile-sub">{{ __wt('cashServiceDeliveredSub', { count: formatInt(report.cashPosition.serviceDeliveredCount) }) }}</div>
            </div>
          </div>

          <div class="cash-tile cash-tile-promo">
            <div class="cash-tile-icon">
              <i class="fas fa-gift"></i>
            </div>
            <div class="cash-tile-body">
              <div class="cash-tile-label">{{ __wt('cashPromoCost') }}</div>
              <div class="cash-tile-value">฿{{ formatNumber(report.cashPosition.promotionalCost) }}</div>
              <div class="cash-tile-sub">{{ __wt('cashPromoCostSub', { count: formatInt(report.cashPosition.promotionalCostCount) }) }}</div>
            </div>
          </div>

          <div class="cash-tile cash-tile-refund">
            <div class="cash-tile-icon">
              <i class="fas fa-undo"></i>
            </div>
            <div class="cash-tile-body">
              <div class="cash-tile-label">{{ __wt('cashRefunded') }}</div>
              <div class="cash-tile-value">฿{{ formatNumber(report.cashPosition.refundedToCustomers) }}</div>
              <div class="cash-tile-sub">{{ __wt('cashRefundedSub', { count: formatInt(report.cashPosition.refundedToCustomersCount) }) }}</div>
            </div>
          </div>
        </div>

        <div class="cash-footnote">
          <i class="fas fa-info-circle"></i>
          {{ __wt('cashFootnote') }}
        </div>
      </div>

      <!-- Promotional Cost detail -->
      <div class="promo-card" v-if="report.promotionalCostDetail">
        <div class="promo-header">
          <div>
            <h2>
              <i class="fas fa-gift"></i>
              {{ __wt('promoTitle') }}
            </h2>
            <p>{{ __wt('promoSubtitle') }}</p>
          </div>
          <div class="promo-total">
            <span class="promo-total-label">{{ __wt('promoTotalLabel') }}</span>
            <span class="promo-total-value">฿{{ formatNumber(report.promotionalCostDetail.total) }}</span>
            <span class="promo-total-sub">{{ __wt('promoTotalSub', { count: formatInt(report.promotionalCostDetail.totalCount) }) }}</span>
          </div>
        </div>

        <div class="promo-split">
          <div class="promo-split-tile">
            <div class="promo-tile-head">
              <i class="fas fa-ticket-alt"></i>
              {{ __wt('promoVouchers') }}
            </div>
            <div class="promo-tile-value">฿{{ formatNumber(report.promotionalCostDetail.voucher.amount) }}</div>
            <div class="promo-tile-sub">
              {{ __wt('promoVoucherCount', { count: formatInt(report.promotionalCostDetail.voucher.count), percent: promoShare(report.promotionalCostDetail.voucher.amount) }) }}
            </div>
          </div>
          <div class="promo-split-tile">
            <div class="promo-tile-head">
              <i class="fas fa-star"></i>
              {{ __wt('promoSystemBonuses') }}
            </div>
            <div class="promo-tile-value">฿{{ formatNumber(report.promotionalCostDetail.systemBonus.amount) }}</div>
            <div class="promo-tile-sub">
              {{ __wt('promoBonusCount', { count: formatInt(report.promotionalCostDetail.systemBonus.count), percent: promoShare(report.promotionalCostDetail.systemBonus.amount) }) }}
            </div>
          </div>
        </div>

        <div class="promo-vouchers" v-if="report.promotionalCostDetail.topVouchers.length">
          <h3>{{ __wt('promoTopVouchers') }}</h3>
          <table class="promo-voucher-table">
            <thead>
              <tr>
                <th>{{ __wt('promoCol_code') }}</th>
                <th>{{ __wt('promoCol_description') }}</th>
                <th class="num">{{ __wt('promoCol_redemptions') }}</th>
                <th class="num">{{ __wt('promoCol_amount') }}</th>
                <th class="num">{{ __wt('promoCol_share') }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="v in report.promotionalCostDetail.topVouchers" :key="v.code">
                <td><code class="voucher-code">{{ v.code }}</code></td>
                <td class="voucher-desc">{{ v.description || '—' }}</td>
                <td class="num">{{ formatInt(v.redemptions) }}</td>
                <td class="num"><strong>฿{{ formatNumber(v.amount) }}</strong></td>
                <td class="num">{{ voucherShare(v.amount) }}%</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Machine Revenue (beer machines, by branch) -->
      <div class="machine-revenue-card">
        <div class="machine-revenue-header">
          <div>
            <h2>
              <i class="fas fa-beer"></i>
              {{ __wt('machinesTitle') }}
            </h2>
            <p>{{ __wt('machinesSubtitle') }}</p>
          </div>
          <div class="machine-revenue-totals">
            <div class="mrev-total">
              <span class="mrev-total-label">{{ __wt('machinesRevenue') }}</span>
              <span class="mrev-total-value">฿{{ formatNumber(machineTotals.revenue) }}</span>
            </div>
            <div class="mrev-total">
              <span class="mrev-total-label">{{ __wt('machinesPours') }}</span>
              <span class="mrev-total-value">{{ formatInt(machineTotals.pours) }}</span>
            </div>
            <div class="mrev-total">
              <span class="mrev-total-label">{{ __wt('machinesVolume') }}</span>
              <span class="mrev-total-value">{{ formatVolume(machineTotals.volumeMl) }}</span>
            </div>
          </div>
        </div>

        <div v-if="machineGroups.length === 0" class="mrev-empty">
          <i class="fas fa-beer"></i>
          <p>{{ __wt('machinesEmpty') }}</p>
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
                <span v-if="group.branchUnattributed" class="mrev-tag">{{ __wt('machinesNoBranch') }}</span>
              </div>
              <div class="mrev-branch-summary">
                <span><strong>฿{{ formatNumber(group.revenue) }}</strong></span>
                <span class="muted">·</span>
                <span>{{ __wt('machinesPoursLabel', { count: formatInt(group.pours) }) }}</span>
                <span class="muted">·</span>
                <span>{{ formatVolume(group.volumeMl) }}</span>
                <span class="muted">·</span>
                <span>{{ branchShareOfTotal(group.revenue) }}%</span>
              </div>
            </div>

            <table class="mrev-table">
              <thead>
                <tr>
                  <th>{{ __wt('machinesCol_machine') }}</th>
                  <th class="num">{{ __wt('machinesCol_pours') }}</th>
                  <th class="num">{{ __wt('machinesCol_volume') }}</th>
                  <th class="num">{{ __wt('machinesCol_revenue') }}</th>
                  <th class="num">{{ __wt('machinesCol_avgPerPour') }}</th>
                  <th class="num">{{ __wt('machinesCol_branchShare') }}</th>
                  <th>{{ __wt('machinesCol_lastActivity') }}</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="m in group.machines"
                  :key="`${group.branch}-${m.machineId || 'unknown'}`"
                  :class="{ 'mrev-unknown': m.machineUnknown }"
                >
                  <td>
                    <template v-if="m.displayName">
                      <div class="machine-display-name">
                        {{ m.displayName }}
                        <span v-if="m.model" class="machine-model">{{ m.model }}</span>
                      </div>
                      <code class="machine-id muted">{{ m.machineId }}</code>
                    </template>
                    <template v-else-if="m.machineId">
                      <code class="machine-id">{{ m.machineId }}</code>
                      <nuxt-link to="/wallets/machines" class="machine-name-link">
                        <i class="fas fa-tag"></i> {{ __wt('machinesNameThis') }}
                      </nuxt-link>
                    </template>
                    <span v-else class="mrev-tag">{{ __wt('machinesUnknown') }}</span>
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
          <div class="stat-label">{{ __wt('rptTotalWalletBalance') }}</div>
          <div class="stat-value">฿{{ formatNumber(report.summary?.totalWalletBalance) }}</div>
          <div class="stat-subtitle">{{ __wt('rptPending') }}: ฿{{ formatNumber(report.summary?.totalPendingBalance) }}</div>
        </div>

        <div class="wallet-stat-card">
          <div class="stat-header">
            <div class="stat-icon success">
              <i class="fas fa-users"></i>
            </div>
          </div>
          <div class="stat-label">{{ __wt('rptActiveWallets') }}</div>
          <div class="stat-value">{{ formatNumber(report.summary?.activeWallets) }}</div>
          <div class="stat-subtitle">{{ __wt('rptFrozen') }}: {{ report.summary?.frozenWallets || 0 }}</div>
        </div>

        <div class="wallet-stat-card">
          <div class="stat-header">
            <div class="stat-icon info">
              <i class="fas fa-exchange-alt"></i>
            </div>
          </div>
          <div class="stat-label">{{ __wt('rptTotalTransactions') }}</div>
          <div class="stat-value">{{ formatNumber(report.transactionSummary?.totalTransactions) }}</div>
          <div class="stat-subtitle">{{ __wt('rptVolume') }}: ฿{{ formatNumber(report.transactionSummary?.totalVolume) }}</div>
        </div>

        <div class="wallet-stat-card">
          <div class="stat-header">
            <div class="stat-icon success">
              <i class="fas fa-coins"></i>
            </div>
          </div>
          <div class="stat-label">{{ __wt('rptRevenue') }}</div>
          <div class="stat-value">฿{{ formatNumber(report.revenue?.totalRevenue) }}</div>
          <div class="stat-subtitle">{{ __wt('rptFromFees') }}</div>
        </div>
      </div>

      <!-- Staff Revenue -->
      <div class="staff-card" v-if="report.byStaff">
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
              <span class="staff-tot-value">{{ formatInt(report.byStaff.length) }}</span>
            </div>
          </div>
        </div>

        <div v-if="report.byStaff.length === 0" class="staff-empty">
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
                v-for="s in report.byStaff"
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

      <!-- Daily Activity -->
      <div class="daily-card" v-if="report.daily">
        <div class="daily-header">
          <div>
            <h2>
              <i class="fas fa-calendar-day"></i>
              {{ __wt('dailyTitle') }}
            </h2>
            <p>{{ __wt('dailySubtitle') }}</p>
          </div>
          <div class="daily-totals">
            <span class="daily-totals-label">{{ __wt('dailyDaysActive', { count: formatInt(report.daily.length) }) }}</span>
          </div>
        </div>

        <div v-if="report.daily.length === 0" class="daily-empty">
          <i class="fas fa-calendar-times"></i>
          <p>{{ __wt('dailyEmpty') }}</p>
        </div>

        <div v-else class="daily-table-wrap">
          <table class="daily-table">
            <thead>
              <tr>
                <th>{{ __wt('dailyCol_date') }}</th>
                <th class="num">{{ __wt('dailyCol_topUps') }}</th>
                <th class="num">{{ __wt('dailyCol_bonus') }}</th>
                <th class="num">{{ __wt('dailyCol_spend') }}</th>
                <th class="num">{{ __wt('dailyCol_refunds') }}</th>
                <th class="num">{{ __wt('dailyCol_transactions') }}</th>
                <th class="num">{{ __wt('dailyCol_netChange') }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in report.daily" :key="row.date">
                <td>
                  <div class="daily-date">{{ formatDailyDate(row.date) }}</div>
                  <div class="daily-weekday">{{ formatDailyWeekday(row.date) }}</div>
                </td>
                <td class="num">{{ row.topUp ? '฿' + formatNumber(row.topUp) : '—' }}</td>
                <td class="num">{{ row.bonus ? '฿' + formatNumber(row.bonus) : '—' }}</td>
                <td class="num">{{ row.spend ? '฿' + formatNumber(row.spend) : '—' }}</td>
                <td class="num">{{ row.refund ? '฿' + formatNumber(row.refund) : '—' }}</td>
                <td class="num">{{ formatInt(row.txCount) }}</td>
                <td :class="['num', row.netChange >= 0 ? 'up' : 'down']">
                  {{ row.netChange >= 0 ? '+' : '−' }}฿{{ formatNumber(Math.abs(row.netChange)) }}
                </td>
              </tr>
            </tbody>
            <tfoot v-if="dailyTotals">
              <tr>
                <td><strong>{{ __wt('dailyPeriodTotal') }}</strong></td>
                <td class="num"><strong>฿{{ formatNumber(dailyTotals.topUp) }}</strong></td>
                <td class="num"><strong>฿{{ formatNumber(dailyTotals.bonus) }}</strong></td>
                <td class="num"><strong>฿{{ formatNumber(dailyTotals.spend) }}</strong></td>
                <td class="num"><strong>฿{{ formatNumber(dailyTotals.refund) }}</strong></td>
                <td class="num"><strong>{{ formatInt(dailyTotals.txCount) }}</strong></td>
                <td :class="['num', dailyTotals.netChange >= 0 ? 'up' : 'down']">
                  <strong>
                    {{ dailyTotals.netChange >= 0 ? '+' : '−' }}฿{{ formatNumber(Math.abs(dailyTotals.netChange)) }}
                  </strong>
                </td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>

      <!-- Attention Items -->
      <div class="attention-card" v-if="report.attentionItems">
        <div class="attention-header">
          <div>
            <h2>
              <i class="fas fa-exclamation-triangle"></i>
              {{ __wt('attTitle') }}
            </h2>
            <p>{{ __wt('attSubtitle') }}</p>
          </div>
          <div
            :class="['attention-count', report.attentionItems.totalItems === 0 ? 'all-clear' : 'has-items']"
          >
            <span v-if="report.attentionItems.totalItems === 0">{{ __wt('attAllClear') }}</span>
            <span v-else>{{ __wt('attItems', { count: formatInt(report.attentionItems.totalItems) }) }}</span>
          </div>
        </div>

        <div class="attention-sections">
          <!-- Stuck pending top-ups -->
          <div class="attention-section">
            <div class="attention-section-head">
              <i class="fas fa-hourglass-half"></i>
              <span>{{ __wt('attStuckPending') }}</span>
              <span class="attention-section-count">
                {{ report.attentionItems.stuckPendingTopUps.length }}
              </span>
            </div>
            <div v-if="report.attentionItems.stuckPendingTopUps.length === 0" class="attention-empty">
              {{ __wt('attStuckEmpty') }}
            </div>
            <table v-else class="attention-table">
              <thead>
                <tr>
                  <th>{{ __wt('attCol_transaction') }}</th>
                  <th>{{ __wt('attCol_user') }}</th>
                  <th>{{ __wt('attCol_method') }}</th>
                  <th class="num">{{ __wt('attCol_amount') }}</th>
                  <th>{{ __wt('attCol_stuckSince') }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="r in report.attentionItems.stuckPendingTopUps" :key="r.id">
                  <td><code class="tx-id">{{ r.id }}</code></td>
                  <td>#{{ r.userId }}</td>
                  <td>{{ r.paymentMethod || '—' }}</td>
                  <td class="num"><strong>฿{{ formatNumber(r.amount) }}</strong></td>
                  <td>{{ formatRelativeDate(r.createdAt) }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Failed transactions -->
          <div class="attention-section">
            <div class="attention-section-head">
              <i class="fas fa-times-circle"></i>
              <span>{{ __wt('attFailed') }}</span>
              <span class="attention-section-count">
                {{ failedTotalCount }}
              </span>
            </div>
            <div v-if="report.attentionItems.failedByType.length === 0" class="attention-empty">
              {{ __wt('attFailedEmpty') }}
            </div>
            <table v-else class="attention-table">
              <thead>
                <tr>
                  <th>{{ __wt('attCol_type') }}</th>
                  <th class="num">{{ __wt('attCol_count') }}</th>
                  <th class="num">{{ __wt('attCol_volumeAttempted') }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="f in report.attentionItems.failedByType" :key="f.type">
                  <td>{{ formatType(f.type) }}</td>
                  <td class="num">{{ formatInt(f.count) }}</td>
                  <td class="num"><strong>฿{{ formatNumber(f.volume) }}</strong></td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Admin adjustments -->
          <div class="attention-section">
            <div class="attention-section-head">
              <i class="fas fa-user-shield"></i>
              <span>{{ __wt('attAdjustments') }}</span>
              <span class="attention-section-count">
                {{ report.attentionItems.adjustments.length }}
              </span>
            </div>
            <div v-if="report.attentionItems.adjustments.length === 0" class="attention-empty">
              {{ __wt('attAdjustmentsEmpty') }}
            </div>
            <table v-else class="attention-table">
              <thead>
                <tr>
                  <th>{{ __wt('attCol_date') }}</th>
                  <th>{{ __wt('attCol_user') }}</th>
                  <th class="num">{{ __wt('attCol_amount') }}</th>
                  <th>{{ __wt('attCol_admin') }}</th>
                  <th>{{ __wt('attCol_reason') }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="a in report.attentionItems.adjustments" :key="a.id">
                  <td>{{ formatStatementDate(a.createdAt) }}</td>
                  <td>#{{ a.userId }}</td>
                  <td :class="['num', a.amount >= 0 ? 'up' : 'down']">
                    <strong>{{ a.amount >= 0 ? '+' : '−' }}฿{{ formatNumber(Math.abs(a.amount)) }}</strong>
                  </td>
                  <td>{{ a.adminUsername || a.adminEmail || '—' }}</td>
                  <td class="reason-cell">{{ a.reason || '—' }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Refunds -->
          <div class="attention-section">
            <div class="attention-section-head">
              <i class="fas fa-undo"></i>
              <span>{{ __wt('attRefunds') }}</span>
              <span class="attention-section-count">
                {{ report.attentionItems.refunds.length }}
              </span>
            </div>
            <div v-if="report.attentionItems.refunds.length === 0" class="attention-empty">
              {{ __wt('attRefundsEmpty') }}
            </div>
            <table v-else class="attention-table">
              <thead>
                <tr>
                  <th>{{ __wt('attCol_date') }}</th>
                  <th>{{ __wt('attCol_user') }}</th>
                  <th class="num">{{ __wt('attCol_amount') }}</th>
                  <th>{{ __wt('attCol_description') }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="r in report.attentionItems.refunds" :key="r.id">
                  <td>{{ formatStatementDate(r.createdAt) }}</td>
                  <td>#{{ r.userId }}</td>
                  <td class="num"><strong>฿{{ formatNumber(r.amount) }}</strong></td>
                  <td class="reason-cell">{{ r.description || '—' }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Stuck vending sessions (point-in-time, not period-bound) -->
          <div class="attention-section" v-if="report.attentionItems.stuckVendingSessions">
            <div class="attention-section-head">
              <i class="fas fa-beer"></i>
              <span>{{ __wt('attStuckVending') }}</span>
              <span class="attention-section-count">
                {{ report.attentionItems.stuckVendingSessions.length }}
              </span>
            </div>
            <div v-if="report.attentionItems.stuckVendingSessions.length === 0" class="attention-empty">
              {{ __wt('attStuckVendingEmpty') }}
            </div>
            <table v-else class="attention-table">
              <thead>
                <tr>
                  <th>{{ __wt('attCol_session') }}</th>
                  <th>{{ __wt('attCol_user') }}</th>
                  <th>{{ __wt('attCol_branch') }}</th>
                  <th>{{ __wt('attCol_machine') }}</th>
                  <th class="num">{{ __wt('attCol_reserved') }}</th>
                  <th>{{ __wt('attCol_stuckSince') }}</th>
                  <th>{{ __wt('attCol_action') }}</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="s in report.attentionItems.stuckVendingSessions"
                  :key="s.sessionId"
                >
                  <td><code class="tx-id">{{ s.sessionId }}</code></td>
                  <td>
                    <nuxt-link :to="`/wallets/${s.userId}`" class="user-link">
                      {{ s.userName }}
                    </nuxt-link>
                  </td>
                  <td>{{ s.branchName || '—' }}</td>
                  <td>
                    <template v-if="s.machineDisplayName">
                      {{ s.machineDisplayName }}
                      <div class="muted-small">{{ s.machineId }}</div>
                    </template>
                    <code v-else-if="s.machineId" class="tx-id">{{ s.machineId }}</code>
                    <span v-else>—</span>
                  </td>
                  <td class="num"><strong>฿{{ formatNumber(s.reservedAmount) }}</strong></td>
                  <td>{{ formatRelativeDate(s.startedAt) }}</td>
                  <td>
                    <button
                      class="wallet-btn danger release-btn"
                      :disabled="releasingSessionId === s.sessionId"
                      @click="releaseStuckSession(s)"
                    >
                      <i class="fas fa-unlock"></i>
                      {{ releasingSessionId === s.sessionId ? __wt('releasing') : __wt('release') }}
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Transaction Breakdown -->
      <div style="background: white; border-radius: 16px; padding: 24px; margin-bottom: 24px; border: 1px solid #E2E8F0; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);">
        <h2 style="font-size: 20px; font-weight: 700; color: #063F48; margin-bottom: 24px;">
          <i class="fas fa-chart-pie"></i>
          {{ __wt('rptTransactionBreakdown') }}
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
              {{ __wt('rptTransactionsLabel', { count: data.count }) }}
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
            {{ __wt('rptVolumeByType') }}
          </h3>
          <div v-if="!hasTypeData" class="chart-empty">
            <i class="fas fa-chart-bar"></i>
            <p>{{ __wt('rptChartEmpty') }}</p>
          </div>
          <div v-else class="chart-canvas-wrap">
            <canvas ref="volumeChart"></canvas>
          </div>
        </div>

        <div class="wallet-stat-card chart-card">
          <h3 class="chart-title">
            <i class="fas fa-chart-pie"></i>
            {{ __wt('rptTransactionsByType') }}
          </h3>
          <div v-if="!hasTypeData" class="chart-empty">
            <i class="fas fa-chart-pie"></i>
            <p>{{ __wt('rptChartEmpty') }}</p>
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
          {{ __wt('rptDetailedStats') }}
        </h2>
        <table class="wallet-table">
          <thead>
            <tr>
              <th><i class="fas fa-tag"></i> {{ __wt('rptMetric') }}</th>
              <th style="text-align: right;"><i class="fas fa-chart-bar"></i> {{ __wt('rptValue') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>{{ __wt('rptStat_totalWalletBalance') }}</td>
              <td style="text-align: right; font-weight: 600; color: #1797AD;">฿{{ formatNumber(report.summary?.totalWalletBalance) }}</td>
            </tr>
            <tr>
              <td>{{ __wt('rptStat_totalPending') }}</td>
              <td style="text-align: right; font-weight: 600; color: #FFB800;">฿{{ formatNumber(report.summary?.totalPendingBalance) }}</td>
            </tr>
            <tr>
              <td>{{ __wt('rptStat_totalFrozen') }}</td>
              <td style="text-align: right; font-weight: 600; color: #6B7280;">฿{{ formatNumber(report.summary?.totalFrozenBalance) }}</td>
            </tr>
            <tr>
              <td>{{ __wt('rptStat_activeWallets') }}</td>
              <td style="text-align: right; font-weight: 600;">{{ report.summary?.activeWallets }}</td>
            </tr>
            <tr>
              <td>{{ __wt('rptStat_frozenWallets') }}</td>
              <td style="text-align: right; font-weight: 600;">{{ report.summary?.frozenWallets }}</td>
            </tr>
            <tr>
              <td>{{ __wt('rptStat_suspendedWallets') }}</td>
              <td style="text-align: right; font-weight: 600;">{{ report.summary?.suspendedWallets }}</td>
            </tr>
            <tr>
              <td>{{ __wt('rptStat_totalTransactions') }}</td>
              <td style="text-align: right; font-weight: 600;">{{ formatNumber(report.transactionSummary?.totalTransactions) }}</td>
            </tr>
            <tr>
              <td>{{ __wt('rptStat_totalVolume') }}</td>
              <td style="text-align: right; font-weight: 600; color: #1797AD;">฿{{ formatNumber(report.transactionSummary?.totalVolume) }}</td>
            </tr>
            <tr>
              <td>{{ __wt('rptStat_topUpFees') }}</td>
              <td style="text-align: right; font-weight: 600; color: #00A862;">฿{{ formatNumber(report.revenue?.topUpFees) }}</td>
            </tr>
            <tr>
              <td>{{ __wt('rptStat_totalRevenue') }}</td>
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
      releasingSessionId: null,
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
    staffGrandTotal() {
      return (this.report.byStaff || []).reduce(
        (s, r) => s + (r.totalCharged || 0),
        0
      );
    },
    generatedAt() {
      return this.$moment().tz('Asia/Bangkok').format('MMM D, YYYY HH:mm');
    },
    failedTotalCount() {
      const items = (this.report.attentionItems && this.report.attentionItems.failedByType) || [];
      return items.reduce((s, f) => s + (f.count || 0), 0);
    },
    dailyTotals() {
      const rows = this.report.daily || [];
      if (rows.length === 0) return null;
      return rows.reduce(
        (acc, r) => ({
          topUp: acc.topUp + r.topUp,
          bonus: acc.bonus + r.bonus,
          spend: acc.spend + r.spend,
          refund: acc.refund + r.refund,
          txCount: acc.txCount + r.txCount,
          netChange: acc.netChange + r.netChange,
        }),
        { topUp: 0, bonus: 0, spend: 0, refund: 0, txCount: 0, netChange: 0 }
      );
    },
    nonZeroCredits() {
      const credits = (this.report.reconciliation && this.report.reconciliation.credits) || [];
      return credits.filter((l) => l.amount > 0 || l.count > 0);
    },
    nonZeroDebits() {
      const debits = (this.report.reconciliation && this.report.reconciliation.debits) || [];
      return debits.filter((l) => l.amount > 0 || l.count > 0);
    },
    totalCredits() {
      return this.nonZeroCredits.reduce((s, l) => s + l.amount, 0);
    },
    totalDebits() {
      return this.nonZeroDebits.reduce((s, l) => s + l.amount, 0);
    },
  },
  async mounted() {
    this.__hydrateWalletUiLang();
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

    printReport() {
      window.print();
    },

    toggleWalletLang() {
      const next = this.$store.state.walletUiLang === 'th' ? 'en' : 'th';
      this.__setWalletUiLang(next);
    },

    async releaseStuckSession(session) {
      const confirm = await this.$swal({
        icon: 'warning',
        title: this.__wt('releaseConfirmTitle'),
        html: this.__wt('releaseConfirmBody', {
          amount: this.formatNumber(session.reservedAmount),
          user: session.userName,
        }),
        input: 'textarea',
        inputPlaceholder: this.__wt('releaseReasonPlaceholder'),
        inputValidator: (value) => {
          if (!value || !value.trim()) return this.__wt('releaseReasonRequired');
        },
        showCancelButton: true,
        confirmButtonText: this.__wt('release'),
        confirmButtonColor: '#cb2731',
      });
      if (!confirm.isConfirmed) return;

      this.releasingSessionId = session.sessionId;
      try {
        await this.$walletService.releaseVendingSession(session.sessionId, confirm.value);
        this.$swal({
          icon: 'success',
          title: this.__wt('releaseSuccess'),
          timer: 1500,
          showConfirmButton: false,
        });
        await this.loadReports();
      } catch (e) {
        this.$swal({
          icon: 'error',
          title: this.__wt('releaseFailed'),
          text: e.response?.data?.error?.message || e.message || '',
        });
      } finally {
        this.releasingSessionId = null;
      }
    },

    // Reconciliation lines arrive from the backend with a stable key.
    // Map that key to a translation entry. Fall back to the backend's
    // English label if a translation key isn't defined.
    translateReconLine(line) {
      const keyMap = {
        top_up_in: 'reconLineTopUps',
        bonus_in: 'reconLineBonuses',
        refund_in: 'reconLineRefunds',
        conversion_in: 'reconLineConversions',
        transfer_in: 'reconLineTransfersIn',
        adjustment_in: 'reconLineAdminCredits',
        store_out: 'reconLineStorePayments',
        beer_out: 'reconLineBeerPayments',
        withdrawal_out: 'reconLineWithdrawals',
        transfer_out: 'reconLineTransfersOut',
        adjustment_out: 'reconLineAdminDebits',
      };
      const i18nKey = keyMap[line.key];
      return i18nKey ? this.__wt(i18nKey) : line.label;
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

      const recon = this.report.reconciliation;
      if (recon) {
        rows.push(['WALLET LIABILITY RECONCILIATION']);
        rows.push(['Line', 'Direction', 'Count', 'Amount']);
        rows.push(['Opening balance', '', '', (recon.openingBalance || 0).toFixed(2)]);
        for (const l of recon.credits || []) {
          rows.push([this.csvCell(l.label), 'credit', l.count, l.amount.toFixed(2)]);
        }
        for (const l of recon.debits || []) {
          rows.push([this.csvCell(l.label), 'debit', l.count, l.amount.toFixed(2)]);
        }
        rows.push(['Net change', '', '', (recon.netChange || 0).toFixed(2)]);
        rows.push(['Computed closing balance', '', '', (recon.computedClosingBalance || 0).toFixed(2)]);
        rows.push(['Actual closing balance', '', '', (recon.actualClosingBalance || 0).toFixed(2)]);
        rows.push(['Gap', '', '', (recon.gap || 0).toFixed(2)]);
        rows.push(['Reconciled', '', '', recon.reconciled ? 'YES' : 'NO']);
        rows.push([]);
      }

      const cash = this.report.cashPosition;
      if (cash) {
        rows.push(['CASH POSITION']);
        rows.push(['Line', 'Count', 'Amount']);
        rows.push(['Cash collected (top-ups)', cash.cashCollectedCount, cash.cashCollected.toFixed(2)]);
        rows.push(['Service delivered (spend)', cash.serviceDeliveredCount, cash.serviceDelivered.toFixed(2)]);
        rows.push(['Promotional cost (bonus/voucher)', cash.promotionalCostCount, cash.promotionalCost.toFixed(2)]);
        rows.push(['Refunded to customers', cash.refundedToCustomersCount, cash.refundedToCustomers.toFixed(2)]);
        rows.push(['Net cash position change', '', cash.netCashPosition.toFixed(2)]);
        rows.push([]);
      }

      const daily = this.report.daily || [];
      if (daily.length > 0) {
        rows.push(['DAILY ACTIVITY']);
        rows.push(['Date', 'Top-ups', 'Bonus/Voucher', 'Spend', 'Refunds', 'Transactions', 'Net change']);
        for (const d of daily) {
          rows.push([
            d.date,
            d.topUp.toFixed(2),
            d.bonus.toFixed(2),
            d.spend.toFixed(2),
            d.refund.toFixed(2),
            d.txCount,
            d.netChange.toFixed(2),
          ]);
        }
        rows.push([]);
      }

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

      const promo = this.report.promotionalCostDetail;
      if (promo) {
        rows.push(['PROMOTIONAL COST']);
        rows.push(['Category', 'Count', 'Amount']);
        rows.push(['Voucher redemptions', promo.voucher.count, promo.voucher.amount.toFixed(2)]);
        rows.push(['System bonuses', promo.systemBonus.count, promo.systemBonus.amount.toFixed(2)]);
        rows.push(['Total', promo.totalCount, promo.total.toFixed(2)]);
        if (promo.topVouchers && promo.topVouchers.length) {
          rows.push([]);
          rows.push(['TOP VOUCHERS']);
          rows.push(['Code', 'Description', 'Redemptions', 'Amount']);
          for (const v of promo.topVouchers) {
            rows.push([
              this.csvCell(v.code),
              this.csvCell(v.description || ''),
              v.redemptions,
              v.amount.toFixed(2),
            ]);
          }
        }
        rows.push([]);
      }

      const att = this.report.attentionItems;
      if (att) {
        rows.push(['ATTENTION: STUCK PENDING TOP-UPS']);
        rows.push(['Transaction ID', 'User ID', 'Method', 'Amount', 'Created at']);
        for (const r of att.stuckPendingTopUps) {
          rows.push([
            this.csvCell(r.id),
            r.userId,
            this.csvCell(r.paymentMethod || ''),
            r.amount.toFixed(2),
            r.createdAt ? this.$moment(r.createdAt).tz('Asia/Bangkok').format('YYYY-MM-DD HH:mm') : '',
          ]);
        }
        rows.push([]);

        rows.push(['ATTENTION: FAILED TRANSACTIONS']);
        rows.push(['Type', 'Count', 'Volume']);
        for (const f of att.failedByType) {
          rows.push([this.csvCell(f.type), f.count, f.volume.toFixed(2)]);
        }
        rows.push([]);

        rows.push(['ATTENTION: ADMIN ADJUSTMENTS']);
        rows.push(['Date', 'Transaction ID', 'User ID', 'Amount', 'Admin', 'Reason']);
        for (const a of att.adjustments) {
          rows.push([
            a.createdAt ? this.$moment(a.createdAt).tz('Asia/Bangkok').format('YYYY-MM-DD HH:mm') : '',
            this.csvCell(a.id),
            a.userId,
            a.amount.toFixed(2),
            this.csvCell(a.adminUsername || a.adminEmail || ''),
            this.csvCell(a.reason || ''),
          ]);
        }
        rows.push([]);

        rows.push(['ATTENTION: REFUNDS']);
        rows.push(['Date', 'Transaction ID', 'User ID', 'Amount', 'Description']);
        for (const r of att.refunds) {
          rows.push([
            r.createdAt ? this.$moment(r.createdAt).tz('Asia/Bangkok').format('YYYY-MM-DD HH:mm') : '',
            this.csvCell(r.id),
            r.userId,
            r.amount.toFixed(2),
            this.csvCell(r.description || ''),
          ]);
        }
        rows.push([]);
      }

      rows.push(['BEER MACHINE REVENUE']);
      rows.push(['Branch', 'Machine ID', 'Display name', 'Model', 'Pours', 'Volume (ml)', 'Revenue', 'Avg per pour', 'Last activity']);
      for (const m of this.report.byMachine || []) {
        const avg = m.pours ? m.revenue / m.pours : 0;
        const last = m.lastActivity
          ? this.$moment(m.lastActivity).tz('Asia/Bangkok').format('YYYY-MM-DD HH:mm')
          : '';
        rows.push([
          this.csvCell(m.branch),
          this.csvCell(m.machineId || 'unknown'),
          this.csvCell(m.displayName || ''),
          this.csvCell(m.model || ''),
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

    formatStatementDate(date) {
      if (!date) return '';
      return this.$moment(date).tz('Asia/Bangkok').format('MMM D, YYYY HH:mm');
    },

    formatDailyDate(date) {
      if (!date) return '';
      return this.$moment(date, 'YYYY-MM-DD').format('MMM D, YYYY');
    },

    formatDailyWeekday(date) {
      if (!date) return '';
      return this.$moment(date, 'YYYY-MM-DD').format('dddd');
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

    staffShareOfTotal(amount) {
      const total = this.staffGrandTotal;
      if (!total) return '0.0';
      return ((amount / total) * 100).toFixed(1);
    },

    goToStaff(staff) {
      const id = staff.unattributed ? '__unattributed__' : staff.staffId;
      const query = {};
      const range = this.filters || {};
      if (range.fromDate) query.fromDate = range.fromDate;
      if (range.toDate) query.toDate = range.toDate;
      this.$router.push({
        path: `/wallets/staff/${encodeURIComponent(id)}`,
        query,
      });
    },

    promoShare(amount) {
      const total = this.report.promotionalCostDetail && this.report.promotionalCostDetail.total;
      if (!total) return '0.0';
      return ((amount / total) * 100).toFixed(1);
    },

    voucherShare(amount) {
      const voucherTotal =
        this.report.promotionalCostDetail
        && this.report.promotionalCostDetail.voucher
        && this.report.promotionalCostDetail.voucher.amount;
      if (!voucherTotal) return '0.0';
      return ((amount / voucherTotal) * 100).toFixed(1);
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

/* Print-only header. Hidden on screen. */
.print-only {
  display: none;
}

.print-header {
  margin-bottom: 24px;
  padding-bottom: 16px;
  border-bottom: 2px solid #063F48;
}

.print-header h1 {
  margin: 0 0 6px;
  font-size: 22px;
  color: #063F48;
}

.print-period {
  font-size: 14px;
  font-weight: 600;
  color: #1F2937;
}

.print-generated {
  font-size: 12px;
  color: #6B7280;
  margin-top: 4px;
}

/* Reconciliation Statement */
.recon-card {
  background: #fff;
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 24px;
  border: 1px solid #E2E8F0;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
}

.recon-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.recon-header h2 {
  margin: 0 0 4px;
  font-size: 20px;
  font-weight: 700;
  color: #063F48;
}

.recon-header h2 i {
  margin-right: 8px;
  color: #1797AD;
}

.recon-header p {
  margin: 0;
  font-size: 13px;
  color: #6B7280;
  max-width: 540px;
}

.recon-status {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  border-radius: 999px;
  font-size: 13px;
  font-weight: 700;
}

.recon-status.ok {
  background: rgba(0, 168, 98, 0.12);
  color: #00794a;
}

.recon-status.mismatch {
  background: rgba(228, 88, 88, 0.12);
  color: #b03333;
}

.recon-statement {
  border: 1px solid #E5E7EB;
  border-radius: 12px;
  overflow: hidden;
  font-variant-numeric: tabular-nums;
}

.recon-row {
  display: grid;
  grid-template-columns: 1fr auto auto;
  gap: 16px;
  align-items: baseline;
  padding: 12px 18px;
  border-bottom: 1px solid #F1F5F9;
}

.recon-row:last-child {
  border-bottom: none;
}

.recon-label {
  font-size: 14px;
  color: #1F2937;
}

.recon-sub {
  font-size: 12px;
  color: #9CA3AF;
}

.recon-amount {
  font-size: 14px;
  font-weight: 600;
  color: #1F2937;
  text-align: right;
}

.recon-amount.muted {
  color: #9CA3AF;
  font-weight: 500;
}

.recon-amount.up { color: #00794a; }
.recon-amount.down { color: #b03333; }

.recon-section-head {
  padding: 10px 18px;
  background: #F7FAFC;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: #4B5563;
  border-bottom: 1px solid #E5E7EB;
}

.recon-section-head i {
  margin-right: 6px;
  color: #1797AD;
}

.recon-credit .recon-amount { color: #00794a; }
.recon-debit .recon-amount { color: #b03333; }

.recon-opening {
  background: #F0F9FA;
}

.recon-opening .recon-label {
  font-weight: 700;
  color: #063F48;
}

.recon-opening .recon-amount {
  font-weight: 700;
  color: #063F48;
}

.recon-subtotal {
  background: #F9FAFB;
  border-top: 1px solid #E5E7EB;
}

.recon-subtotal .recon-label {
  font-weight: 600;
}

.recon-net {
  background: #F0F9FA;
  border-top: 2px solid #1797AD;
  border-bottom: 2px solid #1797AD;
}

.recon-net .recon-label {
  font-weight: 700;
  color: #063F48;
  font-size: 15px;
}

.recon-net .recon-amount {
  font-size: 15px;
  font-weight: 800;
}

.recon-closing,
.recon-actual {
  background: #F7FAFC;
}

.recon-actual .recon-label,
.recon-actual .recon-amount {
  font-weight: 700;
  color: #063F48;
  font-size: 15px;
}

.recon-gap {
  background: rgba(228, 88, 88, 0.08);
  border-top: 2px dashed #b03333;
}

.recon-gap .recon-label {
  font-weight: 700;
  color: #b03333;
}

.recon-gap .recon-amount {
  font-weight: 800;
  color: #b03333;
  font-size: 16px;
}

.recon-empty .recon-label {
  color: #9CA3AF;
  font-style: italic;
}

.recon-footnote {
  margin-top: 16px;
  font-size: 12px;
  color: #6B7280;
  line-height: 1.5;
}

.recon-footnote i {
  color: #1797AD;
  margin-right: 4px;
}

.recon-footnote code {
  background: #F1F5F9;
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 11px;
}

@media (max-width: 640px) {
  .recon-row {
    grid-template-columns: 1fr auto;
    grid-template-areas:
      "label amount"
      "sub   amount";
    row-gap: 4px;
  }

  .recon-label { grid-area: label; }
  .recon-amount { grid-area: amount; }
  .recon-sub { grid-area: sub; }
}

/* Promotional Cost card */
.promo-card {
  background: #fff;
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 24px;
  border: 1px solid #E2E8F0;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
}

.promo-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.promo-header h2 {
  margin: 0 0 4px;
  font-size: 20px;
  font-weight: 700;
  color: #063F48;
}

.promo-header h2 i {
  margin-right: 8px;
  color: #FFB800;
}

.promo-header p {
  margin: 0;
  font-size: 13px;
  color: #6B7280;
}

.promo-total {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  padding: 10px 16px;
  border-radius: 12px;
  background: rgba(255, 184, 0, 0.1);
  border: 2px solid #FFB800;
}

.promo-total-label {
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #92400e;
}

.promo-total-value {
  font-size: 22px;
  font-weight: 800;
  color: #92400e;
  font-variant-numeric: tabular-nums;
}

.promo-total-sub {
  font-size: 11px;
  color: #92400e;
}

.promo-split {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
  margin-bottom: 20px;
}

.promo-split-tile {
  padding: 16px;
  border-radius: 12px;
  background: #F9FAFB;
  border: 1px solid #E5E7EB;
}

.promo-tile-head {
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: #6B7280;
  margin-bottom: 8px;
}

.promo-tile-head i {
  margin-right: 6px;
  color: #FFB800;
}

.promo-tile-value {
  font-size: 22px;
  font-weight: 700;
  color: #063F48;
  font-variant-numeric: tabular-nums;
  margin-bottom: 4px;
}

.promo-tile-sub {
  font-size: 12px;
  color: #6B7280;
}

.promo-vouchers h3 {
  font-size: 14px;
  font-weight: 600;
  color: #063F48;
  margin: 0 0 12px;
}

.promo-voucher-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  font-variant-numeric: tabular-nums;
  border: 1px solid #E5E7EB;
  border-radius: 12px;
  overflow: hidden;
}

.promo-voucher-table thead th {
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

.promo-voucher-table th.num,
.promo-voucher-table td.num {
  text-align: right;
}

.promo-voucher-table tbody td {
  padding: 10px 12px;
  border-bottom: 1px solid #F1F5F9;
  color: #1F2937;
}

.promo-voucher-table tbody tr:last-child td {
  border-bottom: none;
}

.voucher-code {
  font-family: 'SF Mono', Menlo, Consolas, monospace;
  font-size: 12px;
  padding: 2px 8px;
  background: rgba(255, 184, 0, 0.15);
  border-radius: 6px;
  color: #92400e;
  font-weight: 600;
}

.voucher-desc {
  color: #6B7280;
  max-width: 320px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* Attention Items card */
.attention-card {
  background: #fff;
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 24px;
  border: 1px solid #E2E8F0;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
}

.attention-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.attention-header h2 {
  margin: 0 0 4px;
  font-size: 20px;
  font-weight: 700;
  color: #063F48;
}

.attention-header h2 i {
  margin-right: 8px;
  color: #E45858;
}

.attention-header p {
  margin: 0;
  font-size: 13px;
  color: #6B7280;
}

.attention-count {
  display: inline-flex;
  align-items: center;
  padding: 6px 16px;
  border-radius: 999px;
  font-size: 13px;
  font-weight: 700;
}

.attention-count.all-clear {
  background: rgba(0, 168, 98, 0.12);
  color: #00794a;
}

.attention-count.has-items {
  background: rgba(228, 88, 88, 0.12);
  color: #b03333;
}

.attention-sections {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.attention-section {
  border: 1px solid #E5E7EB;
  border-radius: 12px;
  overflow: hidden;
}

.attention-section-head {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  background: #F7FAFC;
  font-size: 14px;
  font-weight: 700;
  color: #063F48;
  border-bottom: 1px solid #E5E7EB;
}

.attention-section-head i {
  color: #E45858;
}

.attention-section-count {
  margin-left: auto;
  padding: 2px 10px;
  border-radius: 999px;
  background: #fff;
  color: #4B5563;
  font-size: 12px;
  font-weight: 600;
  border: 1px solid #E5E7EB;
}

.attention-empty {
  padding: 20px;
  text-align: center;
  font-size: 13px;
  color: #9CA3AF;
}

.attention-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  font-variant-numeric: tabular-nums;
}

.attention-table thead th {
  text-align: left;
  padding: 10px 12px;
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  font-weight: 600;
  color: #6B7280;
  border-bottom: 1px solid #F1F5F9;
  background: #FAFBFC;
}

.attention-table th.num,
.attention-table td.num {
  text-align: right;
}

.attention-table tbody td {
  padding: 10px 12px;
  border-bottom: 1px solid #F1F5F9;
  color: #1F2937;
}

.attention-table tbody tr:last-child td {
  border-bottom: none;
}

.attention-table td.up { color: #00794a; }
.attention-table td.down { color: #b03333; }

.tx-id {
  font-family: 'SF Mono', Menlo, Consolas, monospace;
  font-size: 11px;
  padding: 2px 6px;
  background: #F1F5F9;
  border-radius: 4px;
  color: #4B5563;
}

.reason-cell {
  max-width: 300px;
  color: #6B7280;
  font-size: 12px;
}

.user-link {
  color: #1797AD;
  font-weight: 600;
  text-decoration: none;
}
.user-link:hover { text-decoration: underline; }

.muted-small {
  font-size: 10px;
  color: #9CA3AF;
  margin-top: 2px;
  font-family: 'SF Mono', Menlo, Consolas, monospace;
}

.release-btn {
  padding: 4px 12px;
  font-size: 12px;
}
.release-btn[disabled] { opacity: 0.6; cursor: wait; }

/* Staff Revenue card */
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

.staff-header h2 i {
  margin-right: 8px;
  color: #7C5CFF;
}

.staff-header p {
  margin: 0;
  font-size: 13px;
  color: #6B7280;
}

.staff-totals {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
}

.staff-tot {
  text-align: right;
}

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
.staff-empty i {
  font-size: 32px;
  display: block;
  margin-bottom: 8px;
  color: #D1D5DB;
}

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

.staff-table th.num,
.staff-table td.num { text-align: right; }

.staff-table tbody td {
  padding: 12px;
  border-bottom: 1px solid #F1F5F9;
  color: #1F2937;
}

.staff-row {
  cursor: pointer;
  transition: background 0.12s ease;
}
.staff-row:hover td { background: #F9FAFB; }

.staff-row-unattributed {
  background: rgba(245, 158, 11, 0.04);
}
.staff-row-unattributed:hover td { background: rgba(245, 158, 11, 0.1); }

.staff-name {
  font-weight: 600;
  color: #063F48;
}

.staff-id {
  font-family: 'SF Mono', Menlo, Consolas, monospace;
  font-size: 11px;
  color: #9CA3AF;
}

.branch-count-tag {
  display: inline-block;
  margin-left: 6px;
  padding: 1px 6px;
  font-size: 10px;
  font-weight: 600;
  color: #6B7280;
  background: #F1F5F9;
  border-radius: 999px;
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

@media (max-width: 640px) {
  .promo-split {
    grid-template-columns: 1fr;
  }

  .promo-voucher-table,
  .attention-table {
    font-size: 12px;
  }
}

/* Cash Position card */
.cash-card {
  background: #fff;
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 24px;
  border: 1px solid #E2E8F0;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
}

.cash-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.cash-header h2 {
  margin: 0 0 4px;
  font-size: 20px;
  font-weight: 700;
  color: #063F48;
}

.cash-header h2 i {
  margin-right: 8px;
  color: #00A862;
}

.cash-header p {
  margin: 0;
  font-size: 13px;
  color: #6B7280;
}

.cash-net-pill {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  padding: 10px 16px;
  border-radius: 12px;
  background: #F7FAFC;
  border: 2px solid #E2E8F0;
}

.cash-net-pill.up {
  background: rgba(0, 168, 98, 0.08);
  border-color: #00A862;
}

.cash-net-pill.down {
  background: rgba(228, 88, 88, 0.08);
  border-color: #E45858;
}

.cash-net-label {
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #6B7280;
}

.cash-net-amount {
  font-size: 20px;
  font-weight: 800;
}

.cash-net-pill.up .cash-net-amount { color: #00794a; }
.cash-net-pill.down .cash-net-amount { color: #b03333; }

.cash-tiles {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 14px;
}

.cash-tile {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px;
  border-radius: 12px;
  background: #F9FAFB;
  border: 1px solid #E5E7EB;
}

.cash-tile-icon {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  flex-shrink: 0;
}

.cash-tile-in .cash-tile-icon {
  background: rgba(0, 168, 98, 0.12);
  color: #00794a;
}

.cash-tile-out .cash-tile-icon {
  background: rgba(23, 151, 173, 0.12);
  color: #1797AD;
}

.cash-tile-promo .cash-tile-icon {
  background: rgba(255, 184, 0, 0.18);
  color: #92400e;
}

.cash-tile-refund .cash-tile-icon {
  background: rgba(228, 88, 88, 0.12);
  color: #b03333;
}

.cash-tile-body {
  min-width: 0;
}

.cash-tile-label {
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: #6B7280;
  margin-bottom: 2px;
}

.cash-tile-value {
  font-size: 20px;
  font-weight: 700;
  color: #063F48;
  font-variant-numeric: tabular-nums;
}

.cash-tile-sub {
  font-size: 12px;
  color: #9CA3AF;
  margin-top: 2px;
}

.cash-footnote {
  margin-top: 16px;
  font-size: 12px;
  color: #6B7280;
  line-height: 1.5;
}

.cash-footnote i {
  color: #00A862;
  margin-right: 4px;
}

/* Daily Activity card */
.daily-card {
  background: #fff;
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 24px;
  border: 1px solid #E2E8F0;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
}

.daily-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.daily-header h2 {
  margin: 0 0 4px;
  font-size: 20px;
  font-weight: 700;
  color: #063F48;
}

.daily-header h2 i {
  margin-right: 8px;
  color: #7C5CFF;
}

.daily-header p {
  margin: 0;
  font-size: 13px;
  color: #6B7280;
  max-width: 540px;
}

.daily-totals-label {
  font-size: 13px;
  font-weight: 600;
  color: #6B7280;
  padding: 6px 14px;
  background: #F7FAFC;
  border-radius: 999px;
}

.daily-empty {
  padding: 48px 20px;
  text-align: center;
  color: #6B7280;
}

.daily-empty i {
  font-size: 32px;
  display: block;
  margin-bottom: 8px;
  color: #D1D5DB;
}

.daily-table-wrap {
  border: 1px solid #E5E7EB;
  border-radius: 12px;
  overflow-x: auto;
}

.daily-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  font-variant-numeric: tabular-nums;
}

.daily-table thead th {
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

.daily-table th.num,
.daily-table td.num {
  text-align: right;
}

.daily-table tbody td {
  padding: 12px;
  border-bottom: 1px solid #F1F5F9;
  color: #1F2937;
}

.daily-table tbody tr:last-child td {
  border-bottom: none;
}

.daily-table tbody tr:hover td {
  background: #F9FAFB;
}

.daily-table tfoot td {
  padding: 14px 12px;
  background: #F0F9FA;
  border-top: 2px solid #1797AD;
  color: #063F48;
}

.daily-table td.up { color: #00794a; }
.daily-table td.down { color: #b03333; }

.daily-date {
  font-weight: 600;
  color: #1F2937;
  white-space: nowrap;
}

.daily-weekday {
  font-size: 11px;
  color: #9CA3AF;
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

.machine-id.muted {
  background: transparent;
  color: #9CA3AF;
  padding: 0;
  font-size: 11px;
}

.machine-display-name {
  font-weight: 600;
  color: #063F48;
  font-size: 13px;
  margin-bottom: 2px;
}

.machine-model {
  display: inline-block;
  margin-left: 6px;
  padding: 1px 8px;
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: #4B5563;
  background: #E5E7EB;
  border-radius: 999px;
  vertical-align: middle;
}

.machine-name-link {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  margin-left: 8px;
  font-size: 11px;
  color: #1797AD;
  text-decoration: none;
  font-weight: 600;
}

.machine-name-link:hover {
  text-decoration: underline;
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

/* ============================================================
   Print stylesheet — clean PDF output via window.print()
   ============================================================ */
@media print {
  /* Hide screen-only chrome: filters, action buttons, charts. */
  .no-print,
  .charts-grid {
    display: none !important;
  }

  /* Reveal print-only blocks. */
  .print-only {
    display: block !important;
  }

  /* Page setup. A4 with generous margins. */
  @page {
    size: A4;
    margin: 16mm 14mm;
  }

  /* Strip the page chrome around the report. The admin layout uses
     fixed nav / scroll containers that interfere with print. */
  body,
  html {
    background: #fff !important;
  }

  /* Force background colors and borders to print (Chrome / Safari). */
  * {
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
  }

  .wallet-page-container {
    background: #fff !important;
    padding: 0 !important;
    max-width: 100% !important;
  }

  /* Cards: avoid splitting across pages where possible. */
  .recon-card,
  .cash-card,
  .promo-card,
  .machine-revenue-card,
  .daily-card,
  .attention-card,
  .wallet-stat-card,
  .wallet-table-container {
    box-shadow: none !important;
    border: 1px solid #c0c8d0 !important;
    break-inside: avoid;
    page-break-inside: avoid;
    margin-bottom: 14px !important;
  }

  /* Tables: keep header with body across page breaks. */
  table {
    page-break-inside: auto;
  }
  thead {
    display: table-header-group;
  }
  tr {
    page-break-inside: avoid;
  }

  /* Reduce padding so reports fit more per page. */
  .recon-card,
  .cash-card,
  .promo-card,
  .machine-revenue-card,
  .daily-card,
  .attention-card {
    padding: 14px !important;
  }

  /* The reconciliation section heads use background — keep visible. */
  .recon-section-head,
  .recon-opening,
  .recon-subtotal,
  .recon-net,
  .recon-closing,
  .recon-actual,
  .recon-gap {
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
  }

  /* Footnotes still useful in PDF. */
  .recon-footnote,
  .cash-footnote {
    font-size: 10px;
    color: #4B5563 !important;
  }

  /* Hide Breadcrumb on print — it's screen navigation, not report. */
  .Breadcrumb,
  nav,
  aside {
    display: none !important;
  }
}

.wallet-lang-toggle {
  font-weight: 600;
  letter-spacing: 0.02em;
}
</style>
