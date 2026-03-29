<template>
  <div>
    <AppHeader
      :left="{
        text: 'Back',
        icon: 'chevron-left',
        callback: () => $router.push('/account'),
      }"
    />
    <AlertToast />
    <div class="container _pdt-32px">
      <TextHeading title="ชาร์จเงินกระเป๋า" />

      <!-- Scanner Status -->
      <div class="scanner-status" :class="{ '-scanning': !pending, '-validating': pending }">
        <div class="status-icon">
          <i v-if="!pending" class="fas fa-qrcode"></i>
          <i v-else class="fas fa-spinner fa-spin"></i>
        </div>
        <p class="status-text">
          {{ pending ? 'กำลังตรวจสอบ QR Code...' : 'เตรียมพร้อมสแกน' }}
        </p>
      </div>

      <!-- Instructions -->
      <div class="instructions _mgt-24px _mgbt-32px">
        <div class="instruction-item">
          <div class="step-number">1</div>
          <p>ให้ลูกค้าเปิดหน้า "Pay" ในแอพ</p>
        </div>
        <div class="instruction-item">
          <div class="step-number">2</div>
          <p>นำกล้องสแกน QR Code ที่ลูกค้าแสดง</p>
        </div>
        <div class="instruction-item">
          <div class="step-number">3</div>
          <p>ระบบจะแสดงข้อมูลและยอดเงินอัตโนมัติ</p>
        </div>
      </div>

      <!-- QR Scanner -->
      <client-only>
        <div class="scanner-wrapper">
          <QRScanner @decode="onDecode" v-if="showScanner" />
        </div>
      </client-only>

      <!-- Quick Tips -->
      <div class="quick-tips _mgt-32px">
        <p class="_fs-6 _fw-700 _mgbt-12px">
          <i class="fas fa-lightbulb _mgr-8px"></i>
          เคล็ดลับ
        </p>
        <ul class="tips-list">
          <li>QR Code มีอายุ 15 นาที และจะรีเฟรชอัตโนมัติ</li>
          <li>หากสแกนไม่ได้ ให้ลูกค้ากดปุ่ม "Refresh QR Code"</li>
          <li>ตรวจสอบยอดเงินคงเหลือก่อนทำรายการ</li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  middleware: "auth",
  data() {
    return {
      pending: false,
      showScanner: true,
    };
  },
  mounted() {
    // Clear any previous errors when entering payment page
    this.$store.commit("SET_BY_KEY", {
      key: "paymentError",
      value: null,
    });
    this.$store.commit("SET_BY_KEY", {
      key: "paymentData",
      value: null,
    });
    console.log('[Payment] Scanner ready');
  },
  methods: {
    async onDecode(value) {
      if (this.pending) {
        console.log('[Payment] Already processing, ignoring...');
        return;
      }

      this.pending = true;
      console.log('[Payment] Validating QR code...');

      try {
        const result = await this.validateQR(value);

        if (result.success) {
          console.log('[Payment] Validation successful!');
          const { data } = result;
          this.$store.commit("SET_BY_KEY", {
            key: "paymentData",
            value: {
              nonce: data.nonce,
              user: data.user,
              wallet: data.wallet,
              purpose: data.purpose,
            },
          });
          this.$router.push(`/payment/confirm`);
        } else {
          console.log('[Payment] Validation failed:', result.error);
          this.$store.commit("SET_BY_KEY", {
            key: "paymentError",
            value: result.error,
          });
          this.$router.push(`/payment/failed`);
        }
      } catch (error) {
        console.error('[Payment] Unexpected error:', error);
        this.$store.commit("SET_BY_KEY", {
          key: "paymentError",
          value: 'เกิดข้อผิดพลาดในการตรวจสอบ QR Code',
        });
        this.$router.push(`/payment/failed`);
      } finally {
        // Reset pending after a delay to prevent immediate re-scanning
        setTimeout(() => {
          this.pending = false;
          console.log('[Payment] Ready for next scan');
        }, 1000);
      }
    },
    async validateQR(token) {
      try {
        // Use the public axios instance that completely bypasses authentication
        const response = await this.$publicAxios.post(
          "/wallet/payment-qr/validate",
          { token }
        );

        if (response.data && response.data.success && response.data.data) {
          return { success: true, data: response.data.data };
        } else {
          return { success: false, error: response.data?.message || "Invalid QR code" };
        }
      } catch (e) {
        let message = "QR Code ไม่ถูกต้องหรือหมดอายุแล้ว";

        if (e.response && e.response.data) {
          // Handle nested error structure from backend
          const data = e.response.data;
          if (data.message && typeof data.message === 'object' && data.message.error) {
            message = data.message.error.message || message;
          } else if (typeof data.message === 'string') {
            message = data.message;
          } else if (data.error && typeof data.error === 'object' && data.error.message) {
            message = data.error.message;
          }
        }

        console.error('[Payment] validateQR error:', e);
        return { success: false, error: String(message) };
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.scanner-status {
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  border-radius: 12px;
  padding: 20px;
  text-align: center;
  margin-top: 24px;
  border: 2px solid #e9ecef;
  transition: all 0.3s ease;

  &.-scanning {
    border-color: #1797ad;
    background: linear-gradient(135deg, #e8f5f7 0%, #d4eef3 100%);
  }

  &.-validating {
    border-color: #ffc107;
    background: linear-gradient(135deg, #fff9e6 0%, #fff3cd 100%);
  }

  .status-icon {
    font-size: 48px;
    margin-bottom: 12px;

    i {
      color: #1797ad;
    }
  }

  .status-text {
    font-size: 16px;
    font-weight: 600;
    color: #495057;
    margin: 0;
  }
}

.instructions {
  .instruction-item {
    display: flex;
    align-items: flex-start;
    margin-bottom: 16px;
    padding: 12px;
    background: #f8f9fa;
    border-radius: 8px;
    border-left: 4px solid #1797ad;

    .step-number {
      min-width: 32px;
      height: 32px;
      background: #1797ad;
      color: white;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 700;
      font-size: 16px;
      margin-right: 12px;
    }

    p {
      margin: 0;
      padding-top: 4px;
      color: #495057;
      font-size: 14px;
      line-height: 1.6;
    }
  }
}

.scanner-wrapper {
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  border: 3px solid #1797ad;
}

.quick-tips {
  background: #fff9e6;
  border-radius: 8px;
  padding: 16px;
  border-left: 4px solid #ffc107;

  p {
    color: #856404;
    margin: 0;
  }

  .tips-list {
    list-style: none;
    margin: 0;
    padding: 0;

    li {
      color: #856404;
      font-size: 13px;
      line-height: 1.8;
      padding-left: 20px;
      position: relative;

      &:before {
        content: "•";
        position: absolute;
        left: 0;
        color: #ffc107;
        font-weight: bold;
        font-size: 18px;
      }
    }
  }
}
</style>
