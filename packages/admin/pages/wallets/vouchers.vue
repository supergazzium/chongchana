<template>
  <div class="wallet-page-container">
    <Breadcrumb :items="breadcrumbs" />

    <!-- Page Header -->
    <div class="wallet-page-header">
      <div>
        <h1>Promotions & Vouchers</h1>
        <p class="subtitle">Manage wallet promotions and voucher campaigns</p>
      </div>
      <div class="header-actions">
        <button @click="activeTab = 'promotions'" class="wallet-btn secondary">
          <i class="fas fa-bullhorn"></i>
          Promotions
        </button>
        <button @click="activeTab = 'vouchers'" class="wallet-btn secondary">
          <i class="fas fa-ticket-alt"></i>
          Vouchers
        </button>
      </div>
    </div>

    <!-- Tabs -->
    <div class="wallet-filter-chips">
      <button
        :class="['wallet-filter-chip', { active: activeTab === 'promotions' }]"
        @click="activeTab = 'promotions'"
      >
        <i class="fas fa-bullhorn"></i>
        Wallet Promotions
        <span class="badge">{{ samplePromotions.length }}</span>
      </button>
      <button
        :class="['wallet-filter-chip', { active: activeTab === 'vouchers' }]"
        @click="activeTab = 'vouchers'"
      >
        <i class="fas fa-ticket-alt"></i>
        Voucher Codes
        <span class="badge">{{ sampleVouchers.length }}</span>
      </button>
    </div>

    <!-- Promotions Tab -->
    <div v-if="activeTab === 'promotions'" class="tab-content">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px;">
        <h2 style="font-size: 20px; font-weight: 700; color: #063F48; margin: 0;">
          <i class="fas fa-bullhorn"></i>
          Active Campaigns
        </h2>
        <button @click="showPromotionDialog = true" class="wallet-btn primary">
          <i class="fas fa-plus-circle"></i>
          Create Campaign
        </button>
      </div>

      <div class="promotions-list">
        <div v-for="promotion in samplePromotions" :key="promotion.id" class="promotion-card">
          <div class="promotion-header">
            <div style="display: flex; align-items: center; gap: 12px;">
              <div class="promotion-icon" :class="getPromotionIconClass(promotion.type)">
                <i :class="getPromotionIcon(promotion.type)"></i>
              </div>
              <div>
                <h3>{{ promotion.campaignName }}</h3>
                <span :class="['wallet-status-badge', promotion.status]">{{ promotion.status }}</span>
              </div>
            </div>
            <button class="wallet-btn secondary" style="padding: 8px 16px;" @click="editPromotion(promotion)">
              <i class="fas fa-edit"></i>
              Edit
            </button>
          </div>
          <div class="promotion-body">
            <div class="promo-stats">
              <div class="promo-stat">
                <div class="stat-icon-sm info">
                  <i class="fas fa-tag"></i>
                </div>
                <div>
                  <div class="stat-label-sm">Type</div>
                  <div class="stat-value-sm">{{ formatPromotionType(promotion.type) }}</div>
                </div>
              </div>
              <div class="promo-stat">
                <div class="stat-icon-sm success">
                  <i class="fas fa-gift"></i>
                </div>
                <div>
                  <div class="stat-label-sm">Bonus</div>
                  <div class="stat-value-sm">{{ formatBonus(promotion) }}</div>
                </div>
              </div>
              <div class="promo-stat">
                <div class="stat-icon-sm warning">
                  <i class="fas fa-calendar-alt"></i>
                </div>
                <div>
                  <div class="stat-label-sm">Valid Period</div>
                  <div class="stat-value-sm">{{ formatDate(promotion.validFrom) }} - {{ formatDate(promotion.validUntil) }}</div>
                </div>
              </div>
              <div class="promo-stat">
                <div class="stat-icon-sm info">
                  <i class="fas fa-users"></i>
                </div>
                <div>
                  <div class="stat-label-sm">Target</div>
                  <div class="stat-value-sm">{{ promotion.targetUsers }}</div>
                </div>
              </div>
              <div class="promo-stat">
                <div class="stat-icon-sm success">
                  <i class="fas fa-check-circle"></i>
                </div>
                <div>
                  <div class="stat-label-sm">Redemptions</div>
                  <div class="stat-value-sm">{{ promotion.redemptionCount }} times</div>
                </div>
              </div>
              <div class="promo-stat">
                <div class="stat-icon-sm warning">
                  <i class="fas fa-wallet"></i>
                </div>
                <div>
                  <div class="stat-label-sm">Budget Used</div>
                  <div class="stat-value-sm">฿{{ formatNumber(promotion.usedBudget) }} / ฿{{ formatNumber(promotion.totalBudget) }}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Vouchers Tab -->
    <div v-if="activeTab === 'vouchers'" class="tab-content">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px;">
        <h2 style="font-size: 20px; font-weight: 700; color: #063F48; margin: 0;">
          <i class="fas fa-ticket-alt"></i>
          Voucher Management
        </h2>
        <div style="display: flex; gap: 12px;">
          <button @click="showVoucherDialog = true" class="wallet-btn primary">
            <i class="fas fa-plus-circle"></i>
            Create Voucher
          </button>
          <button @click="showBulkDialog = true" class="wallet-btn secondary">
            <i class="fas fa-layer-group"></i>
            Bulk Generate
          </button>
          <button @click="exportVouchers" class="wallet-btn success">
            <i class="fas fa-download"></i>
            Export CSV
          </button>
        </div>
      </div>

      <!-- Filters -->
      <div class="wallet-filters-panel">
        <div class="wallet-filters-grid">
          <div class="wallet-filter-item">
            <label>
              <i class="fas fa-search"></i>
              Search Code
            </label>
            <input
              v-model="voucherFilters.search"
              type="text"
              placeholder="Search by code..."
            />
          </div>
          <div class="wallet-filter-item">
            <label>
              <i class="fas fa-filter"></i>
              Status Filter
            </label>
            <select v-model="voucherFilters.status">
              <option value="">All Statuses</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="expired">Expired</option>
              <option value="depleted">Depleted</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Vouchers Grid -->
      <div class="vouchers-grid">
        <div v-for="voucher in filteredVouchers" :key="voucher.id" class="voucher-card">
          <div class="voucher-icon">
            <i class="fas fa-ticket-alt"></i>
          </div>
          <div class="voucher-code">{{ voucher.code }}</div>
          <div class="voucher-amount">฿{{ formatNumber(voucher.amount) }}</div>
          <div class="voucher-info">
            <div class="voucher-info-row">
              <i class="fas fa-calendar-alt"></i>
              {{ formatDate(voucher.validFrom) }} - {{ formatDate(voucher.validUntil) }}
            </div>
            <div class="voucher-info-row">
              <i class="fas fa-check-circle"></i>
              Used: {{ voucher.currentRedemptions }} / {{ voucher.maxRedemptions || '∞' }}
            </div>
            <div class="voucher-info-row">
              <i class="fas fa-user"></i>
              Per User: {{ voucher.perUserLimit }}
            </div>
            <div v-if="voucher.conditions" class="voucher-tags">
              <span v-if="voucher.conditions.firstTimeOnly" class="tag">
                <i class="fas fa-star"></i>
                First-time only
              </span>
              <span v-if="voucher.conditions.minTopUp" class="tag">
                <i class="fas fa-wallet"></i>
                Min: ฿{{ voucher.conditions.minTopUp }}
              </span>
            </div>
            <div>
              <span :class="['wallet-status-badge', voucher.status]">{{ voucher.status }}</span>
            </div>
          </div>
          <div class="voucher-actions">
            <button @click="viewRedemptions(voucher)" class="wallet-btn secondary" style="flex: 1; font-size: 12px; padding: 8px 12px;">
              <i class="fas fa-chart-bar"></i>
              View Stats
            </button>
            <button @click="toggleVoucherStatus(voucher)" class="wallet-btn" :class="voucher.status === 'active' ? 'danger' : 'success'" style="flex: 1; font-size: 12px; padding: 8px 12px;">
              <i :class="voucher.status === 'active' ? 'fas fa-ban' : 'fas fa-check-circle'"></i>
              {{ voucher.status === 'active' ? 'Deactivate' : 'Activate' }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Create Promotion Modal -->
    <div v-if="showPromotionDialog" class="modal-overlay" @click="showPromotionDialog = false">
      <div class="modal-content large" @click.stop>
        <div class="modal-header">
          <h2>
            <i class="fas fa-bullhorn"></i>
            Create Wallet Promotion
          </h2>
          <button @click="showPromotionDialog = false" class="modal-close">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>
              <i class="fas fa-tag"></i>
              Campaign Name *
            </label>
            <input
              v-model="promotionForm.campaignName"
              type="text"
              class="form-control"
              placeholder="e.g., Grand Opening Bonus"
            />
          </div>

          <div class="form-group">
            <label>
              <i class="fas fa-gift"></i>
              Promotion Type *
            </label>
            <div class="radio-group">
              <label class="radio-label">
                <input v-model="promotionForm.type" type="radio" value="top_up_bonus" />
                <i class="fas fa-percentage"></i>
                Top-up Bonus (e.g., +10% on all top-ups)
              </label>
              <label class="radio-label">
                <input v-model="promotionForm.type" type="radio" value="fixed_bonus" />
                <i class="fas fa-coins"></i>
                Fixed Bonus (e.g., ฿50 for first top-up)
              </label>
              <label class="radio-label">
                <input v-model="promotionForm.type" type="radio" value="tiered_bonus" />
                <i class="fas fa-layer-group"></i>
                Tiered Bonus (different amounts per tier)
              </label>
            </div>
          </div>

          <!-- Top-up Bonus Fields -->
          <div v-if="promotionForm.type === 'top_up_bonus'" class="form-group">
            <label>
              <i class="fas fa-percentage"></i>
              Bonus Percentage (%) *
            </label>
            <input
              v-model="promotionForm.bonusPercentage"
              type="number"
              step="0.01"
              min="0"
              max="100"
              class="form-control"
              placeholder="e.g., 10"
            />
          </div>

          <!-- Fixed Bonus Fields -->
          <div v-if="promotionForm.type === 'fixed_bonus'" class="form-group">
            <label>
              <i class="fas fa-coins"></i>
              Bonus Amount (฿) *
            </label>
            <input
              v-model="promotionForm.bonusAmount"
              type="number"
              step="0.01"
              min="0"
              class="form-control"
              placeholder="e.g., 50.00"
            />
          </div>

          <!-- Tiered Bonus Fields -->
          <div v-if="promotionForm.type === 'tiered_bonus'" class="form-group">
            <label>
              <i class="fas fa-layer-group"></i>
              Bonus Tiers *
            </label>
            <div v-for="(tier, index) in promotionForm.tiers" :key="index" class="tier-row">
              <input
                v-model="tier.minAmount"
                type="number"
                placeholder="Min Amount"
                class="form-control-sm"
              />
              <span>to</span>
              <input
                v-model="tier.maxAmount"
                type="number"
                placeholder="Max Amount"
                class="form-control-sm"
              />
              <span>=</span>
              <input
                v-model="tier.bonus"
                type="number"
                placeholder="Bonus"
                class="form-control-sm"
              />
              <button @click="removeTier(index)" class="btn-remove">
                <i class="fas fa-times"></i>
              </button>
            </div>
            <button @click="addTier" class="btn-add">
              <i class="fas fa-plus"></i>
              Add Tier
            </button>
          </div>

          <div class="form-section">
            <h4>
              <i class="fas fa-cog"></i>
              Conditions
            </h4>
            <div class="form-group">
              <label class="checkbox-label">
                <input v-model="promotionForm.firstTimeOnly" type="checkbox" />
                <i class="fas fa-star"></i>
                First-time top-up only
              </label>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>
                  <i class="fas fa-wallet"></i>
                  Minimum top-up amount (฿)
                </label>
                <input
                  v-model="promotionForm.minTopUp"
                  type="number"
                  step="0.01"
                  class="form-control"
                  placeholder="Optional"
                />
              </div>
              <div class="form-group">
                <label>
                  <i class="fas fa-trophy"></i>
                  Maximum bonus per user (฿)
                </label>
                <input
                  v-model="promotionForm.maxBonusPerUser"
                  type="number"
                  step="0.01"
                  class="form-control"
                  placeholder="Optional"
                />
              </div>
            </div>
          </div>

          <div class="form-section">
            <h4>
              <i class="fas fa-calendar-alt"></i>
              Valid Period *
            </h4>
            <div class="form-row">
              <div class="form-group">
                <label>From</label>
                <input v-model="promotionForm.validFrom" type="date" class="form-control" />
              </div>
              <div class="form-group">
                <label>To</label>
                <input v-model="promotionForm.validUntil" type="date" class="form-control" />
              </div>
            </div>
          </div>

          <div class="form-section">
            <h4>
              <i class="fas fa-users"></i>
              Target Users *
            </h4>
            <div class="radio-group">
              <label class="radio-label">
                <input v-model="promotionForm.targetUsers" type="radio" value="all" />
                <i class="fas fa-globe"></i>
                All users
              </label>
              <label class="radio-label">
                <input v-model="promotionForm.targetUsers" type="radio" value="new_only" />
                <i class="fas fa-user-plus"></i>
                New users only
              </label>
              <label class="radio-label">
                <input v-model="promotionForm.targetUsers" type="radio" value="segments" />
                <i class="fas fa-filter"></i>
                Selected user segments
              </label>
            </div>
          </div>

          <div class="form-group">
            <label>
              <i class="fas fa-dollar-sign"></i>
              Total Budget (฿)
            </label>
            <input
              v-model="promotionForm.totalBudget"
              type="number"
              step="0.01"
              class="form-control"
              placeholder="Optional - leave empty for unlimited"
            />
          </div>

          <div class="modal-actions">
            <button @click="showPromotionDialog = false" class="wallet-btn secondary">
              <i class="fas fa-times"></i>
              Cancel
            </button>
            <button @click="createPromotion" class="wallet-btn primary" :disabled="!canCreatePromotion">
              <i class="fas fa-check"></i>
              Create Campaign
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Create Voucher Modal -->
    <div v-if="showVoucherDialog" class="modal-overlay" @click="showVoucherDialog = false">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h2>
            <i class="fas fa-ticket-alt"></i>
            Create Wallet Voucher
          </h2>
          <button @click="showVoucherDialog = false" class="modal-close">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>
              <i class="fas fa-barcode"></i>
              Voucher Code *
            </label>
            <input
              v-model="voucherForm.code"
              type="text"
              class="form-control"
              placeholder="e.g., WELCOME50"
              @input="voucherForm.code = voucherForm.code.toUpperCase()"
            />
          </div>

          <div class="form-group">
            <label>
              <i class="fas fa-coins"></i>
              Redemption Value (฿) *
            </label>
            <input
              v-model="voucherForm.amount"
              type="number"
              step="0.01"
              class="form-control"
              placeholder="Enter amount"
            />
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>
                <i class="fas fa-hashtag"></i>
                Max Redemptions (Total)
              </label>
              <input
                v-model="voucherForm.maxRedemptions"
                type="number"
                class="form-control"
                placeholder="Leave empty for unlimited"
              />
            </div>
            <div class="form-group">
              <label>
                <i class="fas fa-user"></i>
                Per User Limit
              </label>
              <input
                v-model="voucherForm.perUserLimit"
                type="number"
                class="form-control"
                placeholder="Default: 1"
              />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>
                <i class="fas fa-calendar-alt"></i>
                Valid From *
              </label>
              <input v-model="voucherForm.validFrom" type="date" class="form-control" />
            </div>
            <div class="form-group">
              <label>
                <i class="fas fa-calendar-check"></i>
                Valid Until *
              </label>
              <input v-model="voucherForm.validUntil" type="date" class="form-control" />
            </div>
          </div>

          <div class="form-group">
            <label>
              <i class="fas fa-align-left"></i>
              Description
            </label>
            <textarea
              v-model="voucherForm.description"
              class="form-control"
              rows="2"
              placeholder="Internal description..."
            ></textarea>
          </div>

          <div class="form-group">
            <label class="checkbox-label">
              <input v-model="voucherForm.firstTimeOnly" type="checkbox" />
              <i class="fas fa-star"></i>
              First-time top-up only
            </label>
          </div>

          <div class="form-group">
            <label>
              <i class="fas fa-wallet"></i>
              Minimum Top-up Amount (฿)
            </label>
            <input
              v-model="voucherForm.minTopUp"
              type="number"
              step="0.01"
              class="form-control"
              placeholder="Optional"
            />
          </div>

          <div class="modal-actions">
            <button @click="showVoucherDialog = false" class="wallet-btn secondary">
              <i class="fas fa-times"></i>
              Cancel
            </button>
            <button @click="createVoucher" class="wallet-btn primary" :disabled="!canCreateVoucher">
              <i class="fas fa-check"></i>
              Create Voucher
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Bulk Voucher Generation Modal -->
    <div v-if="showBulkDialog" class="modal-overlay" @click="showBulkDialog = false">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h2>
            <i class="fas fa-layer-group"></i>
            Generate Bulk Voucher Codes
          </h2>
          <button @click="showBulkDialog = false" class="modal-close">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>
              <i class="fas fa-tag"></i>
              Code Prefix *
            </label>
            <input
              v-model="bulkForm.prefix"
              type="text"
              class="form-control"
              placeholder="e.g., PROMO"
              @input="bulkForm.prefix = bulkForm.prefix.toUpperCase()"
            />
          </div>

          <div class="form-group">
            <label>
              <i class="fas fa-hashtag"></i>
              Number of Codes *
            </label>
            <input
              v-model="bulkForm.quantity"
              type="number"
              min="1"
              max="1000"
              class="form-control"
              placeholder="e.g., 100"
            />
          </div>

          <div class="form-group">
            <label>
              <i class="fas fa-coins"></i>
              Value per Code (฿) *
            </label>
            <input
              v-model="bulkForm.amount"
              type="number"
              step="0.01"
              class="form-control"
              placeholder="e.g., 50.00"
            />
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>
                <i class="fas fa-calendar-alt"></i>
                Valid From *
              </label>
              <input v-model="bulkForm.validFrom" type="date" class="form-control" />
            </div>
            <div class="form-group">
              <label>
                <i class="fas fa-calendar-check"></i>
                Valid Until *
              </label>
              <input v-model="bulkForm.validUntil" type="date" class="form-control" />
            </div>
          </div>

          <div class="form-group">
            <label>
              <i class="fas fa-user"></i>
              Per User Limit
            </label>
            <input
              v-model="bulkForm.perUserLimit"
              type="number"
              class="form-control"
              placeholder="Default: 1"
            />
          </div>

          <div class="modal-actions">
            <button @click="showBulkDialog = false" class="wallet-btn secondary">
              <i class="fas fa-times"></i>
              Cancel
            </button>
            <button @click="generateBulkVouchers" class="wallet-btn primary" :disabled="!canGenerateBulk">
              <i class="fas fa-magic"></i>
              Generate Codes
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
  name: 'WalletVouchers',
  middleware: 'auth',
  components: {
    Breadcrumb,
  },
  data() {
    return {
      breadcrumbs: [
        { label: 'Dashboard', path: '/dashboard' },
        { label: 'Wallet Management', path: '/wallets' },
        { label: 'Promotions & Vouchers' },
      ],
      activeTab: 'promotions',
      showPromotionDialog: false,
      showVoucherDialog: false,
      showBulkDialog: false,

      promotionForm: {
        campaignName: '',
        type: 'fixed_bonus',
        bonusAmount: '',
        bonusPercentage: '',
        tiers: [],
        firstTimeOnly: false,
        minTopUp: '',
        maxBonusPerUser: '',
        validFrom: '',
        validUntil: '',
        targetUsers: 'all',
        totalBudget: '',
      },

      voucherForm: {
        code: '',
        amount: '',
        maxRedemptions: null,
        perUserLimit: 1,
        validFrom: '',
        validUntil: '',
        description: '',
        firstTimeOnly: false,
        minTopUp: '',
      },

      bulkForm: {
        prefix: '',
        quantity: '',
        amount: '',
        validFrom: '',
        validUntil: '',
        perUserLimit: 1,
      },

      voucherFilters: {
        search: '',
        status: '',
      },

      samplePromotions: [
        {
          id: 1,
          campaignName: 'Grand Opening Bonus',
          type: 'fixed_bonus',
          bonusAmount: 50,
          validFrom: '2026-03-10',
          validUntil: '2026-03-31',
          targetUsers: 'All users',
          status: 'active',
          redemptionCount: 125,
          usedBudget: 6250,
          totalBudget: 50000,
        },
        {
          id: 2,
          campaignName: 'Top-up Boost March',
          type: 'top_up_bonus',
          bonusPercentage: 10,
          validFrom: '2026-03-01',
          validUntil: '2026-03-31',
          targetUsers: 'All users',
          status: 'active',
          redemptionCount: 89,
          usedBudget: 4450,
          totalBudget: 20000,
        },
        {
          id: 3,
          campaignName: 'VIP Tier Bonus',
          type: 'tiered_bonus',
          validFrom: '2026-02-01',
          validUntil: '2026-02-28',
          targetUsers: 'Selected segments',
          status: 'expired',
          redemptionCount: 45,
          usedBudget: 8900,
          totalBudget: 10000,
        },
      ],

      sampleVouchers: [
        {
          id: 1,
          code: 'WELCOME50',
          amount: 50,
          status: 'active',
          maxRedemptions: 1000,
          currentRedemptions: 45,
          perUserLimit: 1,
          validFrom: '2026-03-01',
          validUntil: '2026-03-31',
          conditions: { firstTimeOnly: true },
        },
        {
          id: 2,
          code: 'BONUS100',
          amount: 100,
          status: 'active',
          maxRedemptions: 500,
          currentRedemptions: 12,
          perUserLimit: 1,
          validFrom: '2026-03-15',
          validUntil: '2026-04-15',
          conditions: { minTopUp: 200 },
        },
        {
          id: 3,
          code: 'MARCH25',
          amount: 25,
          status: 'active',
          maxRedemptions: null,
          currentRedemptions: 234,
          perUserLimit: 1,
          validFrom: '2026-03-01',
          validUntil: '2026-03-31',
          conditions: null,
        },
        {
          id: 4,
          code: 'EXPIRED50',
          amount: 50,
          status: 'expired',
          maxRedemptions: 100,
          currentRedemptions: 78,
          perUserLimit: 1,
          validFrom: '2026-02-01',
          validUntil: '2026-02-28',
          conditions: null,
        },
      ],
    };
  },

  computed: {
    canCreatePromotion() {
      if (!this.promotionForm.campaignName || !this.promotionForm.validFrom || !this.promotionForm.validUntil) {
        return false;
      }
      if (this.promotionForm.type === 'fixed_bonus' && !this.promotionForm.bonusAmount) {
        return false;
      }
      if (this.promotionForm.type === 'top_up_bonus' && !this.promotionForm.bonusPercentage) {
        return false;
      }
      if (this.promotionForm.type === 'tiered_bonus' && this.promotionForm.tiers.length === 0) {
        return false;
      }
      return true;
    },

    canCreateVoucher() {
      return (
        this.voucherForm.code.length > 0 &&
        this.voucherForm.amount > 0 &&
        this.voucherForm.validFrom &&
        this.voucherForm.validUntil
      );
    },

    canGenerateBulk() {
      return (
        this.bulkForm.prefix.length > 0 &&
        this.bulkForm.quantity > 0 &&
        this.bulkForm.amount > 0 &&
        this.bulkForm.validFrom &&
        this.bulkForm.validUntil
      );
    },

    filteredVouchers() {
      return this.sampleVouchers.filter((v) => {
        if (this.voucherFilters.search && !v.code.includes(this.voucherFilters.search.toUpperCase())) {
          return false;
        }
        if (this.voucherFilters.status && v.status !== this.voucherFilters.status) {
          return false;
        }
        return true;
      });
    },
  },

  methods: {
    getPromotionIcon(type) {
      const icons = {
        top_up_bonus: 'fas fa-percentage',
        fixed_bonus: 'fas fa-coins',
        tiered_bonus: 'fas fa-layer-group',
      };
      return icons[type] || 'fas fa-gift';
    },

    getPromotionIconClass(type) {
      const classes = {
        top_up_bonus: 'success',
        fixed_bonus: 'info',
        tiered_bonus: 'warning',
      };
      return classes[type] || 'info';
    },

    formatPromotionType(type) {
      const types = {
        top_up_bonus: 'Top-up Bonus',
        fixed_bonus: 'Fixed Bonus',
        tiered_bonus: 'Tiered Bonus',
      };
      return types[type] || type;
    },

    formatBonus(promotion) {
      if (promotion.type === 'top_up_bonus') {
        return `+${promotion.bonusPercentage}%`;
      }
      if (promotion.type === 'fixed_bonus') {
        return `฿${this.formatNumber(promotion.bonusAmount)}`;
      }
      return 'Tiered';
    },

    formatDate(dateStr) {
      return this.$moment(dateStr).tz('Asia/Bangkok').format('MMM D, YYYY');
    },

    formatNumber(value) {
      if (value === null || value === undefined) return '0';
      return parseFloat(value).toLocaleString('en-US', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
      });
    },

    addTier() {
      this.promotionForm.tiers.push({ minAmount: '', maxAmount: '', bonus: '' });
    },

    removeTier(index) {
      this.promotionForm.tiers.splice(index, 1);
    },

    editPromotion(promotion) {
      this.$swal({
        icon: 'info',
        title: 'Edit Promotion',
        text: 'Edit promotion feature coming soon',
      });
    },

    async createPromotion() {
      try {
        this.$swal({
          icon: 'success',
          title: 'Success',
          text: `Promotion "${this.promotionForm.campaignName}" created successfully`,
        });
        this.showPromotionDialog = false;
        this.resetPromotionForm();
      } catch (error) {
        console.error('Error creating promotion:', error);
        this.$swal({
          icon: 'error',
          title: 'Error',
          text: 'Failed to create promotion',
        });
      }
    },

    async createVoucher() {
      try {
        this.$swal({
          icon: 'success',
          title: 'Success',
          text: `Voucher "${this.voucherForm.code}" created successfully`,
        });
        this.showVoucherDialog = false;
        this.resetVoucherForm();
      } catch (error) {
        console.error('Error creating voucher:', error);
        this.$swal({
          icon: 'error',
          title: 'Error',
          text: 'Failed to create voucher',
        });
      }
    },

    async generateBulkVouchers() {
      try {
        this.$swal({
          icon: 'success',
          title: 'Success',
          text: `Generated ${this.bulkForm.quantity} voucher codes successfully`,
        });
        this.showBulkDialog = false;
        this.resetBulkForm();
      } catch (error) {
        console.error('Error generating vouchers:', error);
        this.$swal({
          icon: 'error',
          title: 'Error',
          text: 'Failed to generate vouchers',
        });
      }
    },

    viewRedemptions(voucher) {
      this.$swal({
        icon: 'info',
        title: `Redemptions for ${voucher.code}`,
        text: `${voucher.currentRedemptions} redemptions. Detail view coming soon.`,
      });
    },

    toggleVoucherStatus(voucher) {
      const newStatus = voucher.status === 'active' ? 'inactive' : 'active';
      this.$swal({
        icon: 'success',
        title: 'Status Updated',
        text: `Voucher ${voucher.code} is now ${newStatus}`,
      });
    },

    exportVouchers() {
      const csvContent = this.convertToCSV(this.sampleVouchers);
      this.downloadCSV(csvContent, 'vouchers-export.csv');
    },

    convertToCSV(data) {
      if (!data || data.length === 0) return '';
      const headers = ['Code', 'Amount', 'Status', 'Max Redemptions', 'Current Redemptions', 'Valid From', 'Valid Until'];
      const rows = data.map((v) => [
        v.code,
        v.amount,
        v.status,
        v.maxRedemptions || 'Unlimited',
        v.currentRedemptions,
        v.validFrom,
        v.validUntil,
      ]);
      return [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    },

    downloadCSV(csvData, filename) {
      const blob = new Blob([csvData], { type: 'text/csv;charset=utf-8;' });
      const link = document.createElement('a');
      if (link.download !== undefined) {
        const url = URL.createObjectURL(blob);
        link.setAttribute('href', url);
        link.setAttribute('download', filename);
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      }
    },

    resetPromotionForm() {
      this.promotionForm = {
        campaignName: '',
        type: 'fixed_bonus',
        bonusAmount: '',
        bonusPercentage: '',
        tiers: [],
        firstTimeOnly: false,
        minTopUp: '',
        maxBonusPerUser: '',
        validFrom: '',
        validUntil: '',
        targetUsers: 'all',
        totalBudget: '',
      };
    },

    resetVoucherForm() {
      this.voucherForm = {
        code: '',
        amount: '',
        maxRedemptions: null,
        perUserLimit: 1,
        validFrom: '',
        validUntil: '',
        description: '',
        firstTimeOnly: false,
        minTopUp: '',
      };
    },

    resetBulkForm() {
      this.bulkForm = {
        prefix: '',
        quantity: '',
        amount: '',
        validFrom: '',
        validUntil: '',
        perUserLimit: 1,
      };
    },
  },
};
</script>

<style scoped>
.tab-content {
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

/* Promotions List */
.promotions-list {
  display: grid;
  gap: 24px;
}

.promotion-card {
  background: white;
  border: 1px solid #E2E8F0;
  border-radius: 16px;
  padding: 24px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
  transition: all 0.25s ease;
}

.promotion-card:hover {
  box-shadow: 0 4px 16px rgba(23, 151, 173, 0.12);
  transform: translateY(-2px);
}

.promotion-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  padding-bottom: 16px;
  border-bottom: 2px solid #E2E8F0;
}

.promotion-header h3 {
  font-size: 18px;
  font-weight: 700;
  color: #063F48;
  margin: 0 0 8px 0;
}

.promotion-icon {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
}

.promotion-icon.success {
  background: rgba(0, 168, 98, 0.12);
  color: #00A862;
}

.promotion-icon.info {
  background: rgba(23, 151, 173, 0.12);
  color: #1797AD;
}

.promotion-icon.warning {
  background: rgba(255, 184, 0, 0.12);
  color: #FFB800;
}

.promotion-body {
  margin-top: 16px;
}

.promo-stats {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 16px;
}

.promo-stat {
  display: flex;
  gap: 12px;
  align-items: flex-start;
  background: #F7FAFC;
  padding: 16px;
  border-radius: 12px;
  border: 1px solid #E2E8F0;
}

.stat-icon-sm {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  flex-shrink: 0;
}

.stat-icon-sm.success {
  background: rgba(0, 168, 98, 0.12);
  color: #00A862;
}

.stat-icon-sm.info {
  background: rgba(23, 151, 173, 0.12);
  color: #1797AD;
}

.stat-icon-sm.warning {
  background: rgba(255, 184, 0, 0.12);
  color: #FFB800;
}

.stat-label-sm {
  font-size: 12px;
  color: #A0AEC0;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-bottom: 4px;
}

.stat-value-sm {
  font-size: 14px;
  font-weight: 600;
  color: #063F48;
}

/* Vouchers Grid */
.vouchers-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 24px;
}

.voucher-card {
  background: white;
  border: 2px solid #E2E8F0;
  border-radius: 16px;
  padding: 24px;
  text-align: center;
  transition: all 0.25s ease;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
}

.voucher-card:hover {
  box-shadow: 0 4px 16px rgba(23, 151, 173, 0.12);
  transform: translateY(-2px);
  border-color: #1797AD;
}

.voucher-icon {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: rgba(23, 151, 173, 0.12);
  color: #1797AD;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  margin: 0 auto 16px;
}

.voucher-code {
  font-size: 20px;
  font-weight: 700;
  font-family: 'Courier New', monospace;
  color: #1797AD;
  margin-bottom: 12px;
  letter-spacing: 2px;
}

.voucher-amount {
  font-size: 32px;
  font-weight: 700;
  color: #063F48;
  margin-bottom: 16px;
}

.voucher-info {
  font-size: 13px;
  color: #6B7280;
  margin-bottom: 16px;
}

.voucher-info-row {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  margin-bottom: 8px;
}

.voucher-info-row i {
  color: #1797AD;
}

.voucher-tags {
  display: flex;
  gap: 8px;
  justify-content: center;
  margin-top: 8px;
  flex-wrap: wrap;
}

.tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 12px;
  background: rgba(23, 151, 173, 0.12);
  color: #1797AD;
  border-radius: 16px;
  font-size: 11px;
  font-weight: 600;
}

.voucher-actions {
  display: flex;
  gap: 8px;
  justify-content: center;
  margin-top: 16px;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(6, 63, 72, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  backdrop-filter: blur(4px);
}

.modal-content {
  background: white;
  border-radius: 16px;
  padding: 0;
  max-width: 600px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 8px 24px rgba(23, 151, 173, 0.15);
}

.modal-content.large {
  max-width: 800px;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px;
  border-bottom: 2px solid #E2E8F0;
}

.modal-header h2 {
  font-size: 20px;
  font-weight: 700;
  color: #063F48;
  margin: 0;
  display: flex;
  align-items: center;
  gap: 12px;
}

.modal-close {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: none;
  background: #F7FAFC;
  color: #4A5568;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.25s ease;
}

.modal-close:hover {
  background: #E2E8F0;
  color: #063F48;
}

.modal-body {
  padding: 24px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
  font-weight: 600;
  font-size: 14px;
  color: #063F48;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.form-control,
.form-control-sm {
  width: 100%;
  padding: 10px 14px;
  border: 2px solid #E2E8F0;
  border-radius: 12px;
  font-size: 14px;
  transition: all 0.15s ease;
  background: white;
}

.form-control:focus,
.form-control-sm:focus {
  outline: none;
  border-color: #1797AD;
  box-shadow: 0 0 0 3px rgba(23, 151, 173, 0.1);
}

.form-control-sm {
  padding: 6px 10px;
  font-size: 13px;
}

.radio-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.radio-label,
.checkbox-label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 500;
  cursor: pointer;
  padding: 12px;
  border-radius: 8px;
  background: #F7FAFC;
  transition: all 0.15s ease;
}

.radio-label:hover,
.checkbox-label:hover {
  background: #E2E8F0;
}

.radio-label input,
.checkbox-label input {
  width: auto;
  margin: 0;
  cursor: pointer;
}

.form-section {
  margin: 24px 0;
  padding: 20px;
  background: #F7FAFC;
  border-radius: 12px;
  border: 1px solid #E2E8F0;
}

.form-section h4 {
  font-size: 16px;
  font-weight: 700;
  margin: 0 0 16px 0;
  color: #063F48;
  display: flex;
  align-items: center;
  gap: 8px;
}

.tier-row {
  display: flex;
  gap: 8px;
  align-items: center;
  margin-bottom: 12px;
}

.tier-row span {
  font-size: 13px;
  color: #6B7280;
  font-weight: 500;
}

.btn-remove {
  padding: 6px 10px;
  background: rgba(211, 47, 47, 0.12);
  color: #D32F2F;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-remove:hover {
  background: rgba(211, 47, 47, 0.2);
}

.btn-add {
  padding: 8px 16px;
  background: rgba(23, 151, 173, 0.12);
  color: #1797AD;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s ease;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.btn-add:hover {
  background: rgba(23, 151, 173, 0.2);
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 24px;
  padding-top: 20px;
  border-top: 2px solid #E2E8F0;
}
</style>
