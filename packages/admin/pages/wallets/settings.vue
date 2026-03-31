<template>
  <div class="wallet-settings-page">
    <Breadcrumb :items="breadcrumbs" />

    <div class="page-header">
      <h1>Wallet & Point Redemption Settings</h1>
      <button
        @click="saveSettings"
        class="btn-primary"
        :disabled="saving || !hasChanges"
      >
        {{ saving ? 'Saving...' : 'Save Changes' }}
      </button>
    </div>

    <div v-if="loading" class="loading-container">
      <p>Loading settings...</p>
    </div>

    <div v-else class="settings-container">
      <!-- Point Redemption Settings -->
      <div class="settings-section">
        <div class="section-header">
          <h2>Point Redemption Settings</h2>
          <p class="section-description">Configure how users can convert their points to wallet cash</p>
        </div>

        <div class="settings-grid">
          <div class="form-group">
            <label for="pointConversionRate">
              Point Conversion Rate
              <span class="help-text">How many points equal ฿1</span>
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
            <p class="help-text-detail">
              Example: If set to 1.0, then 100 points = ฿100. If set to 2.0, then 200 points = ฿100
            </p>
          </div>

          <div class="form-group">
            <label for="pointMinRedemption">
              Minimum Points for Redemption
              <span class="help-text">Minimum points required to redeem</span>
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
          </div>

          <div class="form-group full-width">
            <label class="checkbox-label">
              <input
                v-model="settings.pointRedemptionRequiresApproval"
                type="checkbox"
                class="checkbox-input"
              />
              <span class="checkbox-text">
                Require Admin Approval for Point Redemptions
              </span>
            </label>
            <p class="help-text-detail">
              When enabled, all point redemption requests will be pending until an admin approves them
            </p>
          </div>
        </div>

        <!-- Preview Calculator -->
        <div class="calculator-preview">
          <h3>Redemption Calculator Preview</h3>
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
            <div class="calculator-result">
              <div class="arrow">→</div>
              <div class="result-box">
                <span class="result-label">Wallet Cash:</span>
                <span class="result-value">฿{{ calculateCash(previewPoints) }}</span>
              </div>
            </div>
            <div class="calculator-status">
              <span v-if="previewPoints < settings.pointMinRedemption" class="status-error">
                ⚠️ Below minimum requirement ({{ settings.pointMinRedemption }} points)
              </span>
              <span v-else class="status-success">
                ✓ Valid redemption amount
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- Transfer Settings -->
      <div class="settings-section">
        <div class="section-header">
          <h2>Wallet Transfer Settings</h2>
          <p class="section-description">Configure wallet-to-wallet transfer rules and fees</p>
        </div>

        <div class="settings-grid">
          <div class="form-group">
            <label for="transferFeePercentage">
              Transfer Fee (%)
              <span class="help-text">Percentage fee per transfer</span>
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
          </div>

          <div class="form-group">
            <label for="transferFeeFixed">
              Fixed Transfer Fee
              <span class="help-text">Fixed fee amount per transfer</span>
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
          </div>

          <div class="form-group">
            <label for="transferMinAmount">
              Minimum Transfer Amount
              <span class="help-text">Minimum amount per transfer</span>
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
          </div>

          <div class="form-group">
            <label for="transferMaxAmount">
              Maximum Transfer Amount
              <span class="help-text">Maximum amount per transfer</span>
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
          </div>

          <div class="form-group">
            <label for="transferDailyLimit">
              Daily Transfer Limit
              <span class="help-text">Maximum total amount per day per user</span>
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
          </div>
        </div>

        <!-- Transfer Fee Calculator -->
        <div class="calculator-preview">
          <h3>Transfer Fee Calculator</h3>
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
            <div class="calculator-result">
              <div class="fee-breakdown">
                <div class="fee-item">
                  <span>Percentage Fee ({{ settings.transferFeePercentage }}%):</span>
                  <span>฿{{ calculatePercentageFee(previewTransfer) }}</span>
                </div>
                <div class="fee-item">
                  <span>Fixed Fee:</span>
                  <span>฿{{ settings.transferFeeFixed.toFixed(2) }}</span>
                </div>
                <div class="fee-item total">
                  <span>Total Fee:</span>
                  <span>฿{{ calculateTotalFee(previewTransfer) }}</span>
                </div>
                <div class="fee-item recipient">
                  <span>Recipient Receives:</span>
                  <span>฿{{ calculateRecipientAmount(previewTransfer) }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!--Billboard Settings -->
      <div class="settings-section">
        <div class="section-header">
          <h2>Wallet Billboard Settings</h2>
          <p class="section-description">Configure billboard images displayed in the wallet screen (replaces card section)</p>
        </div>

        <div class="billboard-controls">
          <label class="checkbox-label">
            <input
              v-model="billboardSettings.enabled"
              type="checkbox"
              class="checkbox-input"
            />
            <span class="checkbox-text">
              Enable Billboard
            </span>
          </label>

          <div v-if="billboardSettings.enabled" class="billboard-settings-grid">
            <div class="form-group">
              <label for="autoPlayInterval">
                Auto-play Interval (milliseconds)
                <span class="help-text">Time between slide transitions</span>
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
                <span class="unit">ms (2000-10000)</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Billboard Images -->
        <div v-if="billboardSettings.enabled" class="billboard-images-section">
          <h3>Billboard Images</h3>
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
              class="btn-upload"
              :disabled="uploadingImage"
            >
              <span v-if="!uploadingImage">📤 Upload New Image</span>
              <span v-else>⏳ Uploading...</span>
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
                <div class="drag-handle">☰</div>
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
                  <input
                    v-model="image.linkUrl"
                    type="url"
                    class="form-control link-input"
                    placeholder="Optional: Link URL (e.g., https://example.com/promo)"
                  />
                  <button @click="removeImage(index)" class="btn-remove">
                    🗑️ Remove
                  </button>
                </div>
              </div>
            </draggable>
          </div>
          <div v-else class="no-images">
            <p>No images uploaded yet. Click "Upload New Image" to add billboard images.</p>
          </div>
        </div>

        <!-- Save Billboard Button -->
        <div v-if="billboardSettings.enabled" class="billboard-save-section">
          <button
            @click="saveBillboardSettings"
            class="btn-primary"
            :disabled="savingBillboard"
          >
            {{ savingBillboard ? 'Saving Billboard...' : 'Save Billboard Settings' }}
          </button>
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="action-buttons">
        <button @click="resetChanges" class="btn-secondary" :disabled="!hasChanges">
          Reset Changes
        </button>
        <button
          @click="saveSettings"
          class="btn-primary"
          :disabled="saving || !hasChanges"
        >
          {{ saving ? 'Saving...' : 'Save All Settings' }}
        </button>
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

          // Load billboard settings if available
          if (response.data.settings.billboard) {
            this.billboardSettings = {
              enabled: response.data.settings.billboard.enabled || false,
              autoPlayInterval: response.data.settings.billboard.autoPlayInterval || 5000,
              images: response.data.settings.billboard.images || [],
            };
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
        const response = await this.$axios.put(
          '/api/wallet-admin/billboard-settings',
          {
            enabled: this.billboardSettings.enabled,
            autoPlayInterval: this.billboardSettings.autoPlayInterval,
            images: this.billboardSettings.images,
          }
        );

        if (response.data.success) {
          this.$swal({
            icon: 'success',
            title: 'Billboard Saved',
            text: 'Billboard settings updated successfully',
            timer: 2500,
            showConfirmButton: false,
          });
        }
      } catch (error) {
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
.wallet-settings-page {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

@media (max-width: 768px) {
  .wallet-settings-page {
    padding: 12px;
  }
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
  flex-wrap: wrap;
  gap: 16px;
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .page-header h1 {
    font-size: 22px !important;
  }
}

.page-header h1 {
  font-size: 28px;
  font-weight: 600;
  color: #1f2937;
}

.loading-container {
  text-align: center;
  padding: 60px 20px;
  color: #6b7280;
}

.settings-container {
  display: flex;
  flex-direction: column;
  gap: 30px;
}

.settings-section {
  background: white;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.section-header {
  margin-bottom: 24px;
  padding-bottom: 16px;
  border-bottom: 2px solid #e5e7eb;
}

.section-header h2 {
  font-size: 20px;
  font-weight: 600;
  color: #1f2937;
  margin-bottom: 8px;
}

.section-description {
  font-size: 14px;
  color: #6b7280;
  margin: 0;
}

.settings-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 24px;
  margin-bottom: 30px;
}

@media (max-width: 768px) {
  .settings-grid {
    grid-template-columns: 1fr;
  }
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
  color: #374151;
  margin-bottom: 8px;
  display: flex;
  flex-direction: column;
}

.help-text {
  font-weight: 400;
  font-size: 12px;
  color: #6b7280;
  margin-top: 2px;
}

.help-text-detail {
  font-size: 12px;
  color: #6b7280;
  margin: 8px 0 0 0;
  font-style: italic;
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
  color: #6b7280;
  white-space: nowrap;
  min-width: fit-content;
}

.form-control {
  padding: 10px 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 14px;
  transition: border-color 0.2s;
}

.form-control:focus {
  outline: none;
  border-color: #1a7a89;
  box-shadow: 0 0 0 3px rgba(26, 122, 137, 0.1);
}

.checkbox-label {
  display: flex;
  align-items: flex-start;
  cursor: pointer;
  gap: 10px;
}

.checkbox-input {
  width: 20px;
  height: 20px;
  cursor: pointer;
  margin-top: 2px;
}

.checkbox-text {
  font-weight: 600;
  font-size: 14px;
  color: #374151;
}

.calculator-preview {
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 20px;
  margin-top: 20px;
}

.calculator-preview h3 {
  font-size: 16px;
  font-weight: 600;
  color: #1f2937;
  margin: 0 0 16px 0;
}

.calculator-content {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

@media (max-width: 640px) {
  .calculator-input {
    flex-direction: column !important;
    align-items: flex-start !important;
  }

  .calculator-input label {
    min-width: auto !important;
  }

  .calculator-input .form-control {
    max-width: 100% !important;
  }

  .calculator-result {
    flex-direction: column !important;
    align-items: flex-start !important;
  }

  .arrow {
    transform: rotate(90deg);
  }

  .fee-breakdown {
    font-size: 13px;
  }
}

.calculator-input {
  display: flex;
  align-items: center;
  gap: 12px;
}

.calculator-input label {
  font-weight: 500;
  font-size: 14px;
  color: #374151;
  min-width: 140px;
}

.calculator-input .form-control {
  max-width: 200px;
}

.calculator-result {
  display: flex;
  align-items: center;
  gap: 16px;
}

.arrow {
  font-size: 24px;
  color: #1a7a89;
}

.result-box {
  background: white;
  border: 2px solid #1a7a89;
  border-radius: 6px;
  padding: 12px 20px;
  display: flex;
  gap: 12px;
  align-items: center;
}

.result-label {
  font-size: 14px;
  color: #6b7280;
}

.result-value {
  font-size: 20px;
  font-weight: 700;
  color: #1a7a89;
}

.calculator-status {
  font-size: 14px;
}

.status-error {
  color: #dc2626;
}

.status-success {
  color: #10b981;
}

.fee-breakdown {
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 100%;
}

.fee-item {
  display: flex;
  justify-content: space-between;
  padding: 8px 12px;
  background: white;
  border-radius: 4px;
  font-size: 14px;
}

.fee-item.total {
  border-top: 2px solid #e5e7eb;
  font-weight: 600;
  color: #dc2626;
}

.fee-item.recipient {
  background: #1a7a89;
  color: white;
  font-weight: 600;
}

.action-buttons {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 20px;
  background: #f9fafb;
  border-radius: 8px;
}

.btn-primary,
.btn-secondary {
  padding: 10px 20px;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  border: none;
  transition: all 0.2s;
}

.btn-primary {
  background: #1a7a89;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #156371;
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-secondary {
  background: #f3f4f6;
  color: #1f2937;
  border: 1px solid #d1d5db;
}

.btn-secondary:hover:not(:disabled) {
  background: #e5e7eb;
}

.btn-secondary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Billboard Settings Styles */
.billboard-controls {
  margin-bottom: 24px;
}

.billboard-settings-grid {
  margin-top: 16px;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 24px;
}

.billboard-images-section {
  margin-top: 30px;
  padding-top: 24px;
  border-top: 1px solid #e5e7eb;
}

.billboard-images-section h3 {
  font-size: 18px;
  font-weight: 600;
  color: #1f2937;
  margin: 0 0 12px 0;
}

.image-upload-area {
  display: flex;
  align-items: center;
  gap: 12px;
  margin: 20px 0;
}

.btn-upload {
  padding: 10px 20px;
  background: #1a7a89;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-upload:hover:not(:disabled) {
  background: #156371;
}

.btn-upload:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.upload-progress {
  font-size: 13px;
  color: #6b7280;
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
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  align-items: center;
}

@media (max-width: 768px) {
  .image-item {
    flex-direction: column;
    align-items: stretch;
  }
}

.drag-handle {
  cursor: grab;
  font-size: 20px;
  color: #6b7280;
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
  border-radius: 6px;
  border: 1px solid #d1d5db;
  display: block;
}

@media (max-width: 768px) {
  .image-preview img {
    width: 100%;
    max-width: 400px;
  }
}

.image-info {
  position: absolute;
  bottom: 4px;
  left: 4px;
  right: 4px;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  padding: 4px 8px;
  border-radius: 4px;
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

.link-input {
  font-size: 13px;
}

.btn-remove {
  align-self: flex-start;
  padding: 8px 16px;
  background: #dc2626;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-remove:hover {
  background: #b91c1c;
}

.no-images {
  text-align: center;
  padding: 40px 20px;
  background: #f9fafb;
  border: 2px dashed #d1d5db;
  border-radius: 8px;
  color: #6b7280;
  margin-top: 20px;
}

.billboard-save-section {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid #e5e7eb;
  display: flex;
  justify-content: flex-end;
}
</style>
