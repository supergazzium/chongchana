<template>
  <div class="staff-payment-container">
    <div class="page-header">
      <h1>Staff Payment - Scan Customer QR</h1>
      <p class="subtitle">Scan customer payment QR code to process wallet payment</p>
    </div>

    <!-- QR Scanner Section -->
    <div v-if="!validatedCustomer" class="scanner-section">
      <div class="scanner-card">
        <h2>Step 1: Scan Customer QR Code</h2>

        <!-- QR Scanner -->
        <div id="qr-reader" class="qr-scanner"></div>

        <!-- Manual Input Option -->
        <div class="manual-input-section">
          <p class="or-text">Or enter QR code manually</p>
          <div class="input-group">
            <input
              v-model="manualQRCode"
              type="text"
              placeholder="Paste QR code here..."
              class="manual-input"
              @keyup.enter="validateManualQR"
            />
            <button
              @click="validateManualQR"
              class="btn btn-primary"
              :disabled="isValidating || !manualQRCode"
            >
              <span v-if="isValidating">Validating...</span>
              <span v-else>Validate</span>
            </button>
          </div>
        </div>

        <!-- Scanner Controls -->
        <div class="scanner-controls">
          <button
            @click="startScanner"
            class="btn btn-success"
            :disabled="isScannerActive"
            v-if="!isScannerActive"
          >
            Start Camera Scanner
          </button>
          <button
            @click="stopScanner"
            class="btn btn-danger"
            v-if="isScannerActive"
          >
            Stop Scanner
          </button>
        </div>

        <!-- Error Display -->
        <div v-if="scanError" class="alert alert-error">
          {{ scanError }}
        </div>
      </div>
    </div>

    <!-- Payment Confirmation Section -->
    <div v-if="validatedCustomer" class="payment-section">
      <div class="customer-card">
        <h2>Step 2: Enter Payment Amount</h2>

        <!-- Customer Info -->
        <div class="customer-info">
          <h3>Customer Information</h3>
          <div class="info-row">
            <span class="label">Name:</span>
            <span class="value">{{ validatedCustomer.user.username }}</span>
          </div>
          <div class="info-row">
            <span class="label">Phone:</span>
            <span class="value">{{ validatedCustomer.user.phoneNumber || 'N/A' }}</span>
          </div>
          <div class="info-row">
            <span class="label">Wallet Balance:</span>
            <span class="value balance">฿{{ formatAmount(validatedCustomer.wallet.balance) }}</span>
          </div>
        </div>

        <!-- Payment Form -->
        <div class="payment-form">
          <div class="form-group">
            <label>Payment Amount (฿)</label>
            <input
              v-model.number="paymentAmount"
              type="number"
              step="0.01"
              min="0.01"
              max="10000"
              placeholder="0.00"
              class="amount-input"
              @input="validateAmount"
            />
            <small v-if="amountError" class="error-text">{{ amountError }}</small>
          </div>

          <div class="form-group">
            <label>Description (Optional)</label>
            <input
              v-model="paymentDescription"
              type="text"
              placeholder="E.g., Purchase of beer, food, etc."
              class="description-input"
            />
          </div>

          <!-- Payment Summary -->
          <div class="payment-summary">
            <div class="summary-row">
              <span>Amount to Charge:</span>
              <span class="amount">฿{{ formatAmount(paymentAmount || 0) }}</span>
            </div>
            <div class="summary-row">
              <span>Customer Balance After:</span>
              <span class="amount">
                ฿{{ formatAmount((validatedCustomer.wallet.balance || 0) - (paymentAmount || 0)) }}
              </span>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="action-buttons">
            <button
              @click="cancelPayment"
              class="btn btn-secondary"
              :disabled="isProcessing"
            >
              Cancel
            </button>
            <button
              @click="processPayment"
              class="btn btn-success btn-large"
              :disabled="isProcessing || !isValidPayment"
            >
              <span v-if="isProcessing">Processing...</span>
              <span v-else>Charge ฿{{ formatAmount(paymentAmount || 0) }}</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Success Modal -->
    <div v-if="showSuccessModal" class="modal-overlay" @click="closeSuccessModal">
      <div class="modal success-modal" @click.stop>
        <div class="modal-icon success-icon">✓</div>
        <h2>Payment Successful!</h2>
        <div class="success-details">
          <p><strong>Transaction ID:</strong> {{ paymentResult.transactionId }}</p>
          <p><strong>Amount Charged:</strong> ฿{{ formatAmount(paymentResult.amount) }}</p>
          <p><strong>New Balance:</strong> ฿{{ formatAmount(paymentResult.newBalance) }}</p>
        </div>
        <button @click="closeSuccessModal" class="btn btn-primary">
          Process Another Payment
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { Html5Qrcode } from 'html5-qrcode';

export default {
  name: 'StaffPayment',
  data() {
    return {
      // Scanner state
      html5QrCode: null,
      isScannerActive: false,
      manualQRCode: '',

      // Validation state
      isValidating: false,
      validatedCustomer: null,
      scanError: null,

      // Payment state
      paymentAmount: null,
      paymentDescription: '',
      amountError: null,
      isProcessing: false,

      // Success state
      showSuccessModal: false,
      paymentResult: null,
    };
  },
  computed: {
    isValidPayment() {
      if (!this.paymentAmount || this.paymentAmount <= 0) return false;
      if (this.paymentAmount < 0.01) return false;
      if (this.paymentAmount > 10000) return false;
      if (!this.validatedCustomer) return false;
      if (this.paymentAmount > this.validatedCustomer.wallet.balance) return false;
      return true;
    },
  },
  beforeDestroy() {
    this.stopScanner();
  },
  methods: {
    async startScanner() {
      try {
        this.scanError = null;

        // Initialize QR scanner
        if (!this.html5QrCode) {
          this.html5QrCode = new Html5Qrcode('qr-reader');
        }

        // Start scanning
        await this.html5QrCode.start(
          { facingMode: 'environment' }, // Use back camera
          {
            fps: 10,
            qrbox: { width: 250, height: 250 },
          },
          this.onScanSuccess,
          this.onScanError
        );

        this.isScannerActive = true;
      } catch (error) {
        console.error('[StaffPayment] Start scanner error:', error);
        this.scanError = 'Failed to start camera. Please check camera permissions.';
      }
    },

    async stopScanner() {
      try {
        if (this.html5QrCode && this.isScannerActive) {
          await this.html5QrCode.stop();
          this.isScannerActive = false;
        }
      } catch (error) {
        console.error('[StaffPayment] Stop scanner error:', error);
      }
    },

    async onScanSuccess(decodedText) {
      console.log('[StaffPayment] QR Code scanned:', decodedText);

      // Stop scanner after successful scan
      await this.stopScanner();

      // Validate the QR code
      await this.validateQRCode(decodedText);
    },

    onScanError(errorMessage) {
      // Ignore scan errors (happens frequently when no QR in view)
      // console.log('[StaffPayment] Scan error:', errorMessage);
    },

    async validateManualQR() {
      if (!this.manualQRCode) {
        this.scanError = 'Please enter or paste a QR code';
        return;
      }

      await this.validateQRCode(this.manualQRCode);
    },

    async validateQRCode(token) {
      this.isValidating = true;
      this.scanError = null;

      try {
        const response = await this.$walletService.validatePaymentQR(token);

        if (response.success && response.data) {
          this.validatedCustomer = response.data;
          console.log('[StaffPayment] Customer validated:', this.validatedCustomer);

          // Stop scanner after validation
          await this.stopScanner();
        } else {
          this.scanError = response.message || 'Invalid QR code';
        }
      } catch (error) {
        console.error('[StaffPayment] Validation error:', error);
        this.scanError = error.response?.data?.message ||
                        error.message ||
                        'Failed to validate QR code. Please try again.';
      } finally {
        this.isValidating = false;
      }
    },

    validateAmount() {
      this.amountError = null;

      if (!this.paymentAmount) return;

      if (this.paymentAmount < 0.01) {
        this.amountError = 'Minimum amount is ฿0.01';
      } else if (this.paymentAmount > 10000) {
        this.amountError = 'Maximum amount is ฿10,000';
      } else if (this.paymentAmount > this.validatedCustomer?.wallet.balance) {
        this.amountError = `Insufficient balance. Available: ฿${this.formatAmount(this.validatedCustomer.wallet.balance)}`;
      }
    },

    async processPayment() {
      if (!this.isValidPayment) return;

      // Confirm payment
      const confirmed = confirm(
        `Charge ฿${this.formatAmount(this.paymentAmount)} from ${this.validatedCustomer.user.username}?`
      );

      if (!confirmed) return;

      this.isProcessing = true;
      this.scanError = null;

      try {
        // Get current user info (staff)
        const staffUser = this.$store.state.user || {};

        const response = await this.$walletService.processQRPayment({
          nonce: this.validatedCustomer.nonce,
          amount: this.paymentAmount,
          description: this.paymentDescription || 'Store payment',
          metadata: {
            staffId: staffUser.id,
            staffName: staffUser.username || staffUser.email,
            location: 'Admin Panel',
          },
        });

        if (response.success && response.data) {
          this.paymentResult = response.data;
          this.showSuccessModal = true;
        } else {
          this.scanError = response.message || 'Payment failed';
        }
      } catch (error) {
        console.error('[StaffPayment] Payment error:', error);
        this.scanError = error.response?.data?.message ||
                        error.message ||
                        'Payment processing failed. Please try again.';
      } finally {
        this.isProcessing = false;
      }
    },

    cancelPayment() {
      const confirmed = confirm('Cancel this payment and scan a new QR code?');
      if (confirmed) {
        this.resetPayment();
      }
    },

    closeSuccessModal() {
      this.showSuccessModal = false;
      this.resetPayment();
    },

    resetPayment() {
      this.validatedCustomer = null;
      this.paymentAmount = null;
      this.paymentDescription = '';
      this.amountError = null;
      this.scanError = null;
      this.manualQRCode = '';
      this.paymentResult = null;
    },

    formatAmount(amount) {
      return new Intl.NumberFormat('en-US', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      }).format(amount);
    },
  },
};
</script>

<style scoped>
.staff-payment-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

.page-header {
  text-align: center;
  margin-bottom: 30px;
}

.page-header h1 {
  font-size: 28px;
  color: #333;
  margin-bottom: 8px;
}

.subtitle {
  color: #666;
  font-size: 14px;
}

/* Scanner Section */
.scanner-section {
  margin-bottom: 30px;
}

.scanner-card {
  background: white;
  border-radius: 12px;
  padding: 30px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.scanner-card h2 {
  font-size: 20px;
  margin-bottom: 20px;
  color: #333;
}

.qr-scanner {
  width: 100%;
  max-width: 500px;
  margin: 0 auto 20px;
  border: 2px dashed #ddd;
  border-radius: 8px;
  min-height: 300px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.manual-input-section {
  margin: 30px 0;
}

.or-text {
  text-align: center;
  color: #999;
  margin-bottom: 15px;
  font-size: 14px;
}

.input-group {
  display: flex;
  gap: 10px;
}

.manual-input {
  flex: 1;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 14px;
}

.scanner-controls {
  display: flex;
  justify-content: center;
  margin-top: 20px;
}

/* Payment Section */
.payment-section {
  margin-bottom: 30px;
}

.customer-card {
  background: white;
  border-radius: 12px;
  padding: 30px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.customer-card h2 {
  font-size: 20px;
  margin-bottom: 20px;
  color: #333;
}

.customer-info {
  background: #f8f9fa;
  padding: 20px;
  border-radius: 8px;
  margin-bottom: 30px;
}

.customer-info h3 {
  font-size: 16px;
  margin-bottom: 15px;
  color: #555;
}

.info-row {
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid #e0e0e0;
}

.info-row:last-child {
  border-bottom: none;
}

.info-row .label {
  color: #666;
  font-weight: 500;
}

.info-row .value {
  color: #333;
  font-weight: 600;
}

.info-row .balance {
  color: #28a745;
  font-size: 18px;
}

.payment-form {
  margin-top: 20px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 600;
  color: #333;
}

.amount-input,
.description-input {
  width: 100%;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 16px;
}

.amount-input {
  font-size: 24px;
  font-weight: 600;
}

.error-text {
  color: #dc3545;
  font-size: 13px;
  margin-top: 5px;
  display: block;
}

.payment-summary {
  background: #f8f9fa;
  padding: 20px;
  border-radius: 8px;
  margin: 20px 0;
}

.summary-row {
  display: flex;
  justify-content: space-between;
  padding: 10px 0;
  font-size: 16px;
}

.summary-row .amount {
  font-weight: 700;
  color: #333;
  font-size: 18px;
}

.action-buttons {
  display: flex;
  gap: 15px;
  margin-top: 30px;
}

/* Buttons */
.btn {
  padding: 12px 24px;
  border: none;
  border-radius: 6px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-primary {
  background: #007bff;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #0056b3;
}

.btn-success {
  background: #28a745;
  color: white;
}

.btn-success:hover:not(:disabled) {
  background: #218838;
}

.btn-danger {
  background: #dc3545;
  color: white;
}

.btn-danger:hover:not(:disabled) {
  background: #c82333;
}

.btn-secondary {
  background: #6c757d;
  color: white;
  flex: 1;
}

.btn-secondary:hover:not(:disabled) {
  background: #5a6268;
}

.btn-large {
  flex: 2;
  font-size: 18px;
  padding: 15px 30px;
}

/* Alerts */
.alert {
  padding: 15px;
  border-radius: 6px;
  margin-top: 15px;
}

.alert-error {
  background: #f8d7da;
  color: #721c24;
  border: 1px solid #f5c6cb;
}

/* Modal */
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

.modal {
  background: white;
  border-radius: 12px;
  padding: 40px;
  max-width: 500px;
  width: 90%;
  text-align: center;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}

.modal-icon {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 20px;
  font-size: 48px;
}

.success-icon {
  background: #d4edda;
  color: #28a745;
}

.success-modal h2 {
  color: #28a745;
  margin-bottom: 20px;
}

.success-details {
  background: #f8f9fa;
  padding: 20px;
  border-radius: 8px;
  margin: 20px 0;
  text-align: left;
}

.success-details p {
  margin: 10px 0;
  font-size: 14px;
}

.success-details strong {
  color: #333;
}
</style>