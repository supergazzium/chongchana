<template>
  <div class="wallet-page-container">
    <Breadcrumb :items="breadcrumbs" />

    <!-- Page Header -->
    <div class="wallet-page-header">
      <div>
        <h1>Wallet & Point Settings</h1>
        <p class="subtitle">Configure wallet operations, point redemption, and display settings</p>
      </div>
      <div class="header-actions">
        <button
          @click="resetChanges"
          class="wallet-btn secondary"
          :disabled="!hasChanges"
        >
          <i class="fas fa-undo"></i>
          Reset
        </button>
        <button
          @click="saveSettings"
          class="wallet-btn primary"
          :disabled="saving || !hasChanges"
        >
          <i :class="saving ? 'fas fa-spinner fa-spin' : 'fas fa-save'"></i>
          {{ saving ? 'Saving...' : 'Save Changes' }}
        </button>
      </div>
    </div>

    <div v-if="loading" class="wallet-loading">
      <i class="fas fa-spinner fa-spin"></i>
      <p>Loading settings...</p>
    </div>

    <div v-else class="settings-container">
      <!-- Point Redemption Settings -->
      <div class="settings-section">
        <div class="section-header">
          <div class="section-title">
            <div class="section-icon info">
              <i class="fas fa-coins"></i>
            </div>
            <div>
              <h2>Point Redemption Settings</h2>
              <p class="section-description">Configure how users can convert their points to wallet cash</p>
            </div>
          </div>
        </div>

        <div class="settings-grid">
          <div class="form-group">
            <label for="pointConversionRate">
              <i class="fas fa-exchange-alt"></i>
              Point Conversion Rate
            </label>
            <div class="input-with-unit">
              <input
                id="pointConversionRate"
                v-model.number="settings.pointConversionRate"
                type="number"
                step="0.01"
                min="0.01"
                class="form-control"
                placeholder="1.0"
              />
              <span class="unit">points = ฿1</span>
            </div>
            <p class="help-text">
              Example: If set to 1.0, then 100 points = ฿100. If set to 2.0, then 200 points = ฿100
            </p>
          </div>

          <div class="form-group">
            <label for="pointMinRedemption">
              <i class="fas fa-chart-line"></i>
              Minimum Points for Redemption
            </label>
            <div class="input-with-unit">
              <input
                id="pointMinRedemption"
                v-model.number="settings.pointMinRedemption"
                type="number"
                step="1"
                min="1"
                class="form-control"
                placeholder="100"
              />
              <span class="unit">points</span>
            </div>
            <p class="help-text">Minimum points required to redeem</p>
          </div>

          <div class="form-group full-width">
            <label class="checkbox-label">
              <input
                v-model="settings.pointRedemptionRequiresApproval"
                type="checkbox"
                class="checkbox-input"
              />
              <div class="checkbox-content">
                <i class="fas fa-user-check"></i>
                <div>
                  <span class="checkbox-text">Require Admin Approval for Point Redemptions</span>
                  <p class="help-text">When enabled, all point redemption requests will be pending until an admin approves them</p>
                </div>
              </div>
            </label>
          </div>
        </div>

        <!-- Preview Calculator -->
        <div class="calculator-preview">
          <h3>
            <i class="fas fa-calculator"></i>
            Redemption Calculator Preview
          </h3>
          <div class="calculator-content">
            <div class="calculator-input">
              <label>Points to Redeem:</label>
              <input
                v-model.number="previewPoints"
                type="number"
                step="1"
                min="0"
                class="form-control"
                placeholder="Enter points"
              />
            </div>
            <div class="calculator-arrow">
              <i class="fas fa-arrow-right"></i>
            </div>
            <div class="calculator-result">
              <div class="result-box">
                <span class="result-label">Wallet Cash</span>
                <span class="result-value">฿{{ calculateCash(previewPoints) }}</span>
              </div>
            </div>
          </div>
          <div class="calculator-status">
            <span v-if="previewPoints < settings.pointMinRedemption" class="status-error">
              <i class="fas fa-exclamation-triangle"></i>
              Below minimum requirement ({{ settings.pointMinRedemption }} points)
            </span>
            <span v-else class="status-success">
              <i class="fas fa-check-circle"></i>
              Valid redemption amount
            </span>
          </div>
        </div>
      </div>

      <!-- Transfer Settings -->
      <div class="settings-section">
        <div class="section-header">
          <div class="section-title">
            <div class="section-icon success">
              <i class="fas fa-exchange-alt"></i>
            </div>
            <div>
              <h2>Wallet Transfer Settings</h2>
              <p class="section-description">Configure wallet-to-wallet transfer rules and fees</p>
            </div>
          </div>
        </div>

        <div class="settings-grid">
          <div class="form-group">
            <label for="transferFeePercentage">
              <i class="fas fa-percentage"></i>
              Transfer Fee (%)
            </label>
            <div class="input-with-unit">
              <input
                id="transferFeePercentage"
                v-model.number="settings.transferFeePercentage"
                type="number"
                step="0.01"
                min="0"
                max="100"
                class="form-control"
                placeholder="0"
              />
              <span class="unit">%</span>
            </div>
            <p class="help-text">Percentage fee per transfer</p>
          </div>

          <div class="form-group">
            <label for="transferFeeFixed">
              <i class="fas fa-dollar-sign"></i>
              Fixed Transfer Fee
            </label>
            <div class="input-with-unit">
              <input
                id="transferFeeFixed"
                v-model.number="settings.transferFeeFixed"
                type="number"
                step="0.01"
                min="0"
                class="form-control"
                placeholder="0"
              />
              <span class="unit">฿</span>
            </div>
            <p class="help-text">Fixed fee amount per transfer</p>
          </div>

          <div class="form-group">
            <label for="transferMinAmount">
              <i class="fas fa-arrow-down"></i>
              Minimum Transfer Amount
            </label>
            <div class="input-with-unit">
              <input
                id="transferMinAmount"
                v-model.number="settings.transferMinAmount"
                type="number"
                step="0.01"
                min="0"
                class="form-control"
                placeholder="1"
              />
              <span class="unit">฿</span>
            </div>
            <p class="help-text">Minimum amount per transfer</p>
          </div>

          <div class="form-group">
            <label for="transferMaxAmount">
              <i class="fas fa-arrow-up"></i>
              Maximum Transfer Amount
            </label>
            <div class="input-with-unit">
              <input
                id="transferMaxAmount"
                v-model.number="settings.transferMaxAmount"
                type="number"
                step="0.01"
                min="0"
                class="form-control"
                placeholder="100000"
              />
              <span class="unit">฿</span>
            </div>
            <p class="help-text">Maximum amount per transfer</p>
          </div>

          <div class="form-group">
            <label for="transferDailyLimit">
              <i class="fas fa-calendar-day"></i>
              Daily Transfer Limit
            </label>
            <div class="input-with-unit">
              <input
                id="transferDailyLimit"
                v-model.number="settings.transferDailyLimit"
                type="number"
                step="0.01"
                min="0"
                class="form-control"
                placeholder="1000000"
              />
              <span class="unit">฿</span>
            </div>
            <p class="help-text">Maximum total amount per day per user</p>
          </div>
        </div>

        <!-- Transfer Fee Calculator -->
        <div class="calculator-preview">
          <h3>
            <i class="fas fa-calculator"></i>
            Transfer Fee Calculator
          </h3>
          <div class="calculator-content">
            <div class="calculator-input">
              <label>Transfer Amount:</label>
              <input
                v-model.number="previewTransfer"
                type="number"
                step="0.01"
                min="0"
                class="form-control"
                placeholder="Enter amount"
              />
            </div>
            <div class="fee-breakdown">
              <div class="fee-item">
                <div class="fee-icon info">
                  <i class="fas fa-percentage"></i>
                </div>
                <div class="fee-details">
                  <span class="fee-label">Percentage Fee ({{ settings.transferFeePercentage }}%)</span>
                  <span class="fee-value">฿{{ calculatePercentageFee(previewTransfer) }}</span>
                </div>
              </div>
              <div class="fee-item">
                <div class="fee-icon info">
                  <i class="fas fa-dollar-sign"></i>
                </div>
                <div class="fee-details">
                  <span class="fee-label">Fixed Fee</span>
                  <span class="fee-value">฿{{ settings.transferFeeFixed.toFixed(2) }}</span>
                </div>
              </div>
              <div class="fee-item total">
                <div class="fee-icon warning">
                  <i class="fas fa-equals"></i>
                </div>
                <div class="fee-details">
                  <span class="fee-label">Total Fee</span>
                  <span class="fee-value">฿{{ calculateTotalFee(previewTransfer) }}</span>
                </div>
              </div>
              <div class="fee-item recipient">
                <div class="fee-icon success">
                  <i class="fas fa-arrow-right"></i>
                </div>
                <div class="fee-details">
                  <span class="fee-label">Recipient Receives</span>
                  <span class="fee-value">฿{{ calculateRecipientAmount(previewTransfer) }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Billboard Settings -->
      <div class="settings-section">
        <div class="section-header">
          <div class="section-title">
            <div class="section-icon warning">
              <i class="fas fa-image"></i>
            </div>
            <div>
              <h2>Wallet Billboard Settings</h2>
              <p class="section-description">Configure billboard images displayed in the wallet screen (replaces card section)</p>
            </div>
          </div>
        </div>

        <!-- Current Billboard Status -->
        <div class="billboard-status">
          <div class="status-cards">
            <div class="status-card">
              <div class="status-card-icon" :class="billboardSettings.enabled ? 'success' : 'error'">
                <i :class="billboardSettings.enabled ? 'fas fa-check-circle' : 'fas fa-times-circle'"></i>
              </div>
              <div class="status-card-content">
                <span class="status-card-label">Billboard Status</span>
                <span class="status-card-value" :class="billboardSettings.enabled ? 'success' : 'error'">
                  {{ billboardSettings.enabled ? 'Enabled' : 'Disabled' }}
                </span>
              </div>
            </div>
            <div class="status-card">
              <div class="status-card-icon info">
                <i class="fas fa-images"></i>
              </div>
              <div class="status-card-content">
                <span class="status-card-label">Active Images</span>
                <span class="status-card-value">{{ billboardSettings.images.length }}</span>
              </div>
            </div>
            <div v-if="billboardSettings.enabled && billboardSettings.images.length > 0" class="status-card">
              <div class="status-card-icon warning">
                <i class="fas fa-clock"></i>
              </div>
              <div class="status-card-content">
                <span class="status-card-label">Auto-play Interval</span>
                <span class="status-card-value">{{ billboardSettings.autoPlayInterval / 1000 }}s</span>
              </div>
            </div>
          </div>
        </div>

        <div class="billboard-controls">
          <div class="toggle-switch-group">
            <label class="toggle-label">
              <i class="fas fa-power-off"></i>
              Enable Billboard
            </label>
            <div class="toggle-switch-wrapper">
              <label class="toggle-switch">
                <input
                  v-model="billboardSettings.enabled"
                  type="checkbox"
                  class="toggle-input"
                />
                <span class="toggle-slider"></span>
              </label>
              <span class="toggle-status" :class="billboardSettings.enabled ? 'enabled' : 'disabled'">
                {{ billboardSettings.enabled ? 'Enabled' : 'Disabled' }}
              </span>
            </div>
          </div>

          <div v-if="billboardSettings.enabled" class="billboard-settings-grid">
            <div class="form-group">
              <label for="autoPlayInterval">
                <i class="fas fa-hourglass-half"></i>
                Auto-play Interval
              </label>
              <div class="input-with-unit">
                <input
                  id="autoPlayInterval"
                  v-model.number="billboardSettings.autoPlayInterval"
                  type="number"
                  step="1000"
                  min="2000"
                  max="10000"
                  class="form-control"
                  placeholder="5000"
                />
                <span class="unit">ms</span>
              </div>
              <p class="help-text">Time between slide transitions (2000-10000ms)</p>
            </div>
          </div>
        </div>

        <!-- Billboard Images -->
        <div v-if="billboardSettings.enabled" class="billboard-images-section">
          <h3>
            <i class="fas fa-images"></i>
            Billboard Images
          </h3>
          <p class="help-text-detail">
            <strong>Image Requirements:</strong> 800x450px (min) to 2400x1350px (max).
            <strong>Recommended:</strong> 1200x675px or 1600x900px (16:9 aspect ratio).
            Max file size: 2MB per image. Formats: JPEG, PNG
          </p>

          <!-- Image Upload -->
          <div class="image-upload-area">
            <input
              ref="imageUpload"
              type="file"
              accept="image/jpeg,image/png,image/jpg"
              @change="handleImageUpload"
              style="display: none"
            />
            <button
              @click="$refs.imageUpload.click()"
              class="wallet-btn primary"
              :disabled="uploadingImage"
            >
              <i :class="uploadingImage ? 'fas fa-spinner fa-spin' : 'fas fa-upload'"></i>
              {{ uploadingImage ? 'Uploading...' : 'Upload New Image' }}
            </button>
            <span v-if="uploadProgress" class="upload-progress">{{ uploadProgress }}</span>
          </div>

          <!-- Images List -->
          <div v-if="billboardSettings.images.length > 0" class="images-list">
            <draggable v-model="billboardSettings.images" @end="updateImageOrder" handle=".drag-handle">
              <div
                v-for="(image, index) in billboardSettings.images"
                :key="index"
                class="image-item"
              >
                <div class="drag-handle">
                  <i class="fas fa-grip-vertical"></i>
                </div>
                <div class="image-preview">
                  <img :src="image.imageUrl" alt="Billboard" />
                  <div class="image-info">
                    <span class="image-order">Order: {{ index + 1 }}</span>
                    <span v-if="image.width && image.height" class="image-dimensions">
                      {{ image.width }}x{{ image.height }}px
                    </span>
                  </div>
                </div>
                <div class="image-actions">
                  <div class="form-group" style="margin-bottom: 0;">
                    <label>
                      <i class="fas fa-link"></i>
                      Link URL (Optional)
                    </label>
                    <input
                      v-model="image.linkUrl"
                      type="url"
                      class="form-control"
                      placeholder="e.g., https://example.com/promo"
                    />
                  </div>
                  <button @click="removeImage(index)" class="wallet-btn danger" style="padding: 8px 16px; font-size: 13px;">
                    <i class="fas fa-trash-alt"></i>
                    Remove
                  </button>
                </div>
              </div>
            </draggable>
          </div>
          <div v-else class="wallet-empty">
            <i class="fas fa-images"></i>
            <p>No images uploaded yet. Click "Upload New Image" to add billboard images.</p>
          </div>
        </div>

        <!-- Save Billboard Button -->
        <div class="billboard-save-section">
          <button
            @click="saveBillboardSettings"
            class="wallet-btn success"
            :disabled="savingBillboard"
          >
            <i :class="savingBillboard ? 'fas fa-spinner fa-spin' : 'fas fa-save'"></i>
            {{ savingBillboard ? 'Saving Billboard...' : 'Save Billboard Settings' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Breadcrumb from '~/components/Breadcrumb';
import draggable from 'vuedraggable';

export default {
  name: 'WalletSettings',
  middleware: 'auth',
  components: {
    Breadcrumb,
    draggable,
  },
  data() {
    return {
      breadcrumbs: [
        { label: 'Dashboard', path: '/dashboard' },
        { label: 'Wallet Management', path: '/wallets' },
        { label: 'Settings' },
      ],
      loading: false,
      saving: false,
      settings: {
        pointConversionRate: 1.0,
        pointMinRedemption: 100,
        pointRedemptionRequiresApproval: false,
        transferFeePercentage: 0,
        transferFeeFixed: 0,
        transferMinAmount: 1,
        transferMaxAmount: 100000,
        transferDailyLimit: 1000000,
      },
      originalSettings: null,
      previewPoints: 100,
      previewTransfer: 1000,
      billboardSettings: {
        enabled: false,
        autoPlayInterval: 5000,
        images: [],
      },
      uploadingImage: false,
      uploadProgress: '',
      savingBillboard: false,
    };
  },
  computed: {
    hasChanges() {
      if (!this.originalSettings) return false;
      return JSON.stringify(this.settings) !== JSON.stringify(this.originalSettings);
    },
  },
  async mounted() {
    await this.loadSettings();
  },
  methods: {
    async loadSettings() {
      this.loading = true;
      try {
        const response = await this.$walletService.getTransferSettings();

        if (response.success) {
          this.settings = { ...response.data.settings };
          this.originalSettings = { ...response.data.settings };

          // Load billboard settings from the main settings response
          if (response.data.settings.billboard) {
            this.billboardSettings = {
              enabled: response.data.settings.billboard.enabled || false,
              autoPlayInterval: response.data.settings.billboard.autoPlayInterval || 5000,
              images: response.data.settings.billboard.images || [],
            };
            console.log('[Admin] Loaded billboard settings:', this.billboardSettings);
          } else {
            console.warn('[Admin] No billboard settings found in response');
          }
        }
      } catch (error) {
        console.error('Error loading settings:', error);
        const errorMsg = error.response?.data?.error?.message || error.message || 'Unknown error';

        this.$swal({
          icon: 'error',
          title: 'Failed to Load Settings',
          html: `
            <div style="text-align: left;">
              <p><strong>Error:</strong> ${errorMsg}</p>
              <br/>
              <p><strong>Possible Solutions:</strong></p>
              <ol style="margin-left: 20px;">
                <li>Run the database migration: <code>database/migrations/wallet_transfers_points.sql</code></li>
                <li>Check if backend server is running on port 7001</li>
                <li>Verify database connection in backend</li>
              </ol>
            </div>
          `,
          width: 600,
          confirmButtonText: 'OK',
        });
      } finally {
        this.loading = false;
      }
    },

    async saveSettings() {
      // Validate inputs before saving
      const validation = this.validateSettings();
      if (!validation.valid) {
        this.$swal({
          icon: 'warning',
          title: 'Validation Error',
          html: `
            <div style="text-align: left;">
              <p>Please fix the following issues:</p>
              <ul style="margin-left: 20px; color: #dc2626;">
                ${validation.errors.map(err => `<li>${err}</li>`).join('')}
              </ul>
            </div>
          `,
        });
        return;
      }

      this.saving = true;
      try {
        const response = await this.$walletService.updateTransferSettings(this.settings);

        if (response.success) {
          this.originalSettings = { ...this.settings };
          this.$swal({
            icon: 'success',
            title: 'Settings Saved',
            text: 'All settings have been updated successfully',
            timer: 2500,
            showConfirmButton: false,
          });
        }
      } catch (error) {
        console.error('Error saving settings:', error);
        const errorMsg = error.response?.data?.error?.message || error.message || 'Unknown error';
        this.$swal({
          icon: 'error',
          title: 'Failed to Save Settings',
          text: errorMsg,
          confirmButtonText: 'OK',
        });
      } finally {
        this.saving = false;
      }
    },

    validateSettings() {
      const errors = [];

      // Point Redemption Validation
      if (this.settings.pointConversionRate <= 0) {
        errors.push('Point Conversion Rate must be greater than 0');
      }
      if (this.settings.pointMinRedemption < 1) {
        errors.push('Minimum Points for Redemption must be at least 1');
      }

      // Transfer Settings Validation
      if (this.settings.transferFeePercentage < 0 || this.settings.transferFeePercentage > 100) {
        errors.push('Transfer Fee Percentage must be between 0-100%');
      }
      if (this.settings.transferFeeFixed < 0) {
        errors.push('Fixed Transfer Fee cannot be negative');
      }
      if (this.settings.transferMinAmount < 0) {
        errors.push('Minimum Transfer Amount cannot be negative');
      }
      if (this.settings.transferMaxAmount < this.settings.transferMinAmount) {
        errors.push('Maximum Transfer Amount must be greater than Minimum');
      }
      if (this.settings.transferDailyLimit < this.settings.transferMaxAmount) {
        errors.push('Daily Transfer Limit should be greater than or equal to Maximum Transfer Amount');
      }

      return {
        valid: errors.length === 0,
        errors,
      };
    },

    resetChanges() {
      if (this.originalSettings) {
        this.settings = { ...this.originalSettings };
      }
    },

    calculateCash(points) {
      if (!points || points <= 0) return '0.00';
      const cash = points / this.settings.pointConversionRate;
      return cash.toFixed(2);
    },

    calculatePercentageFee(amount) {
      if (!amount || amount <= 0) return '0.00';
      const fee = (amount * this.settings.transferFeePercentage) / 100;
      return fee.toFixed(2);
    },

    calculateTotalFee(amount) {
      if (!amount || amount <= 0) return '0.00';
      const percentageFee = (amount * this.settings.transferFeePercentage) / 100;
      const totalFee = percentageFee + this.settings.transferFeeFixed;
      return totalFee.toFixed(2);
    },

    calculateRecipientAmount(amount) {
      if (!amount || amount <= 0) return '0.00';
      const totalFee = parseFloat(this.calculateTotalFee(amount));
      const recipient = amount - totalFee;
      return Math.max(0, recipient).toFixed(2);
    },

    // Billboard Management Methods
    async handleImageUpload(event) {
      const file = event.target.files[0];
      if (!file) return;

      this.uploadingImage = true;
      this.uploadProgress = 'Validating and uploading...';

      try {
        const formData = new FormData();
        formData.append('image', file);

        const response = await this.$axios.post(
          '/api/wallet-admin/billboard/upload-image',
          formData,
          {
            headers: { 'Content-Type': 'multipart/form-data' },
          }
        );

        if (response.data.success) {
          const { imageUrl, width, height, recommendations } = response.data.data;

          this.billboardSettings.images.push({
            imageUrl,
            width,
            height,
            order: this.billboardSettings.images.length,
            linkUrl: '',
          });

          this.$swal({
            icon: 'success',
            title: 'Image Uploaded',
            html: `
              <p>Image uploaded successfully!</p>
              <p><strong>Dimensions:</strong> ${width}x${height}px</p>
              <p>${recommendations.message}</p>
            `,
          });
        }
      } catch (error) {
        const errorMsg = error.response?.data?.error?.message || error.message;
        this.$swal({
          icon: 'error',
          title: 'Upload Failed',
          text: errorMsg,
        });
      } finally {
        this.uploadingImage = false;
        this.uploadProgress = '';
        event.target.value = '';
      }
    },

    updateImageOrder() {
      this.billboardSettings.images.forEach((img, index) => {
        img.order = index;
      });
    },

    removeImage(index) {
      this.$swal({
        title: 'Remove Image?',
        text: 'This will remove the image from the billboard.',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Yes, remove it',
        cancelButtonText: 'Cancel',
      }).then((result) => {
        if (result.isConfirmed) {
          this.billboardSettings.images.splice(index, 1);
          this.updateImageOrder();
        }
      });
    },

    async saveBillboardSettings() {
      this.savingBillboard = true;
      try {
        console.log('[Admin] Saving billboard settings:', {
          enabled: this.billboardSettings.enabled,
          autoPlayInterval: this.billboardSettings.autoPlayInterval,
          imagesCount: this.billboardSettings.images.length,
          images: this.billboardSettings.images,
        });

        const response = await this.$axios.put(
          '/api/wallet-admin/billboard-settings',
          {
            enabled: this.billboardSettings.enabled,
            autoPlayInterval: this.billboardSettings.autoPlayInterval,
            images: this.billboardSettings.images,
          }
        );

        if (response.data.success) {
          // Reload settings to ensure UI is in sync with database
          await this.loadSettings();

          this.$swal({
            icon: 'success',
            title: 'Billboard Saved',
            text: 'Billboard settings updated successfully',
            timer: 2500,
            showConfirmButton: false,
          });
        }
      } catch (error) {
        console.error('[Admin] Failed to save billboard:', error);
        const errorMsg = error.response?.data?.error?.message || error.message;
        this.$swal({
          icon: 'error',
          title: 'Failed to Save Billboard',
          text: errorMsg,
        });
      } finally {
        this.savingBillboard = false;
      }
    },
  },
};
</script>

<style scoped>
.settings-container {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.settings-section {
  background: white;
  border-radius: 16px;
  padding: 24px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
  border: 1px solid #E2E8F0;
}

.section-header {
  margin-bottom: 24px;
  padding-bottom: 20px;
  border-bottom: 2px solid #E2E8F0;
}

.section-title {
  display: flex;
  align-items: flex-start;
  gap: 16px;
}

.section-icon {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  flex-shrink: 0;
}

.section-icon.success {
  background: rgba(0, 168, 98, 0.12);
  color: #00A862;
}

.section-icon.warning {
  background: rgba(255, 184, 0, 0.12);
  color: #FFB800;
}

.section-icon.info {
  background: rgba(23, 151, 173, 0.12);
  color: #1797AD;
}

.section-header h2 {
  font-size: 20px;
  font-weight: 700;
  color: #063F48;
  margin: 0 0 8px 0;
}

.section-description {
  font-size: 14px;
  color: #A0AEC0;
  margin: 0;
}

.settings-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 24px;
  margin-bottom: 24px;
}

.form-group {
  display: flex;
  flex-direction: column;
}

.form-group.full-width {
  grid-column: 1 / -1;
}

.form-group label {
  font-weight: 600;
  font-size: 14px;
  color: #063F48;
  margin-bottom: 8px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.help-text,
.help-text-detail {
  font-size: 12px;
  color: #A0AEC0;
  margin-top: 6px;
}

.input-with-unit {
  display: flex;
  align-items: center;
  gap: 8px;
}

.input-with-unit .form-control {
  flex: 1;
}

.unit {
  font-size: 14px;
  color: #6B7280;
  white-space: nowrap;
  font-weight: 500;
}

.form-control {
  padding: 10px 14px;
  border: 2px solid #E2E8F0;
  border-radius: 12px;
  font-size: 14px;
  transition: all 0.15s ease;
  background: white;
}

.form-control:focus {
  outline: none;
  border-color: #1797AD;
  box-shadow: 0 0 0 3px rgba(23, 151, 173, 0.1);
}

.checkbox-label {
  display: flex;
  align-items: flex-start;
  cursor: pointer;
  gap: 12px;
  padding: 16px;
  background: #F7FAFC;
  border-radius: 12px;
  border: 2px solid #E2E8F0;
  transition: all 0.15s ease;
}

.checkbox-label:hover {
  border-color: #1797AD;
  background: rgba(23, 151, 173, 0.05);
}

.checkbox-input {
  width: 20px;
  height: 20px;
  cursor: pointer;
  margin-top: 2px;
  flex-shrink: 0;
}

.checkbox-content {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  flex: 1;
}

.checkbox-content i {
  color: #1797AD;
  font-size: 18px;
  margin-top: 2px;
}

.checkbox-text {
  font-weight: 600;
  font-size: 14px;
  color: #063F48;
}

.calculator-preview {
  background: #F7FAFC;
  border: 1px solid #E2E8F0;
  border-radius: 12px;
  padding: 20px;
  margin-top: 24px;
}

.calculator-preview h3 {
  font-size: 16px;
  font-weight: 700;
  color: #063F48;
  margin: 0 0 16px 0;
  display: flex;
  align-items: center;
  gap: 8px;
}

.calculator-content {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
  margin-bottom: 16px;
}

.calculator-input {
  display: flex;
  align-items: center;
  gap: 12px;
}

.calculator-input label {
  font-weight: 500;
  font-size: 14px;
  color: #063F48;
  min-width: 140px;
}

.calculator-input .form-control {
  max-width: 200px;
}

.calculator-arrow {
  font-size: 24px;
  color: #1797AD;
}

.calculator-result {
  flex: 1;
  min-width: 200px;
}

.result-box {
  background: white;
  border: 2px solid #1797AD;
  border-radius: 12px;
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.result-label {
  font-size: 12px;
  color: #A0AEC0;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-weight: 600;
}

.result-value {
  font-size: 24px;
  font-weight: 700;
  color: #1797AD;
}

.calculator-status {
  font-size: 14px;
  font-weight: 600;
}

.status-error {
  color: #D32F2F;
  display: flex;
  align-items: center;
  gap: 6px;
}

.status-success {
  color: #00A862;
  display: flex;
  align-items: center;
  gap: 6px;
}

.fee-breakdown {
  display: flex;
  flex-direction: column;
  gap: 12px;
  width: 100%;
  margin-top: 16px;
}

.fee-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  background: white;
  border-radius: 12px;
  border: 1px solid #E2E8F0;
}

.fee-icon {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  flex-shrink: 0;
}

.fee-icon.success {
  background: rgba(0, 168, 98, 0.12);
  color: #00A862;
}

.fee-icon.warning {
  background: rgba(255, 184, 0, 0.12);
  color: #FFB800;
}

.fee-icon.info {
  background: rgba(23, 151, 173, 0.12);
  color: #1797AD;
}

.fee-details {
  flex: 1;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.fee-label {
  font-size: 14px;
  color: #4A5568;
  font-weight: 500;
}

.fee-value {
  font-size: 16px;
  color: #063F48;
  font-weight: 700;
}

.fee-item.total {
  border: 2px solid #FFB800;
  background: rgba(255, 184, 0, 0.05);
}

.fee-item.recipient {
  border: 2px solid #00A862;
  background: rgba(0, 168, 98, 0.05);
}

/* Billboard Settings */
.billboard-status {
  background: #F7FAFC;
  border: 1px solid #E2E8F0;
  border-radius: 12px;
  padding: 20px;
  margin-bottom: 24px;
}

.status-cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 16px;
}

.status-card {
  display: flex;
  align-items: center;
  gap: 12px;
  background: white;
  padding: 16px;
  border-radius: 12px;
  border: 1px solid #E2E8F0;
}

.status-card-icon {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  flex-shrink: 0;
}

.status-card-icon.success {
  background: rgba(0, 168, 98, 0.12);
  color: #00A862;
}

.status-card-icon.error {
  background: rgba(211, 47, 47, 0.12);
  color: #D32F2F;
}

.status-card-icon.info {
  background: rgba(23, 151, 173, 0.12);
  color: #1797AD;
}

.status-card-icon.warning {
  background: rgba(255, 184, 0, 0.12);
  color: #FFB800;
}

.status-card-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.status-card-label {
  font-size: 12px;
  color: #A0AEC0;
  font-weight: 500;
}

.status-card-value {
  font-size: 16px;
  color: #063F48;
  font-weight: 700;
}

.status-card-value.success {
  color: #00A862;
}

.status-card-value.error {
  color: #D32F2F;
}

.billboard-controls {
  margin-bottom: 24px;
}

.toggle-switch-group {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px;
  background: #F7FAFC;
  border-radius: 12px;
  border: 1px solid #E2E8F0;
  margin-bottom: 20px;
}

.toggle-label {
  font-size: 14px;
  font-weight: 600;
  color: #063F48;
  display: flex;
  align-items: center;
  gap: 8px;
}

.toggle-switch-wrapper {
  display: flex;
  align-items: center;
  gap: 12px;
}

.toggle-switch {
  position: relative;
  display: inline-block;
  width: 52px;
  height: 28px;
}

.toggle-switch .toggle-input {
  opacity: 0;
  width: 0;
  height: 0;
}

.toggle-slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #E2E8F0;
  transition: 0.3s;
  border-radius: 28px;
}

.toggle-slider:before {
  position: absolute;
  content: "";
  height: 20px;
  width: 20px;
  left: 4px;
  bottom: 4px;
  background-color: white;
  transition: 0.3s;
  border-radius: 50%;
}

.toggle-input:checked + .toggle-slider {
  background-color: #00A862;
}

.toggle-input:focus + .toggle-slider {
  box-shadow: 0 0 1px #00A862;
}

.toggle-input:checked + .toggle-slider:before {
  transform: translateX(24px);
}

.toggle-status {
  font-size: 14px;
  font-weight: 600;
}

.toggle-status.enabled {
  color: #00A862;
}

.toggle-status.disabled {
  color: #6B7280;
}

.billboard-settings-grid {
  margin-top: 16px;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 24px;
}

.billboard-images-section {
  margin-top: 24px;
  padding-top: 24px;
  border-top: 1px solid #E2E8F0;
}

.billboard-images-section h3 {
  font-size: 18px;
  font-weight: 700;
  color: #063F48;
  margin: 0 0 12px 0;
  display: flex;
  align-items: center;
  gap: 8px;
}

.image-upload-area {
  display: flex;
  align-items: center;
  gap: 12px;
  margin: 20px 0;
}

.upload-progress {
  font-size: 13px;
  color: #6B7280;
  font-style: italic;
}

.images-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-top: 20px;
}

.image-item {
  display: flex;
  gap: 16px;
  padding: 16px;
  background: #F7FAFC;
  border: 1px solid #E2E8F0;
  border-radius: 12px;
  align-items: center;
}

.drag-handle {
  cursor: grab;
  font-size: 20px;
  color: #6B7280;
  padding: 8px;
  user-select: none;
}

.drag-handle:active {
  cursor: grabbing;
}

.image-preview {
  flex-shrink: 0;
  position: relative;
}

.image-preview img {
  width: 200px;
  height: auto;
  border-radius: 8px;
  border: 1px solid #E2E8F0;
  display: block;
}

.image-info {
  position: absolute;
  bottom: 4px;
  left: 4px;
  right: 4px;
  background: rgba(6, 63, 72, 0.8);
  color: white;
  padding: 6px 10px;
  border-radius: 6px;
  font-size: 11px;
  display: flex;
  justify-content: space-between;
}

.image-order {
  font-weight: 600;
}

.image-dimensions {
  font-size: 10px;
  opacity: 0.9;
}

.image-actions {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.billboard-save-section {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid #E2E8F0;
  display: flex;
  justify-content: flex-end;
}

@media (max-width: 768px) {
  .settings-grid {
    grid-template-columns: 1fr;
  }

  .section-title {
    flex-direction: column;
    align-items: flex-start;
  }

  .calculator-content {
    flex-direction: column;
    align-items: flex-start;
  }

  .calculator-arrow {
    transform: rotate(90deg);
  }

  .image-item {
    flex-direction: column;
    align-items: stretch;
  }

  .image-preview img {
    width: 100%;
    max-width: 400px;
  }

  .toggle-switch-group {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }
}
</style>
