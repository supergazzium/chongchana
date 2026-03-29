<template>
  <div>
    <AppHeader />
    <div class="container _pdt-32px">
      <FailedContent
        title="ชาร์จเงินไม่สำเร็จ"
        :back="{
          label: 'สแกน QR ใหม่',
          path: '/payment',
        }"
      >
        <div class="error-icon _mgbt-24px">
          <i class="fas fa-exclamation-circle"></i>
        </div>

        <div class="error-message">
          <p class="_tal-ct _fw-600">
            {{ _paymentError || 'การชาร์จเงินล้มเหลว กรุณาลองใหม่อีกครั้ง' }}
          </p>
        </div>

        <div v-if="isExpiredError" class="help-text _mgt-24px">
          <h4>
            <i class="fas fa-lightbulb _mgr-8px"></i>
            แนะนำการแก้ไข:
          </h4>
          <ul>
            <li>QR Code หมดอายุภายใน 15 นาที</li>
            <li>ให้ลูกค้ากดปุ่ม "Refresh QR Code" ในแอพ</li>
            <li>หรือให้ลูกค้าออกจากหน้า Pay แล้วเข้าใหม่</li>
            <li>จากนั้นสแกน QR Code ใหม่ทันที</li>
          </ul>
        </div>
      </FailedContent>
    </div>
  </div>
</template>

<script>
import FailedContent from "~/components/FailedContent";

export default {
  middleware: "auth",
  components: {
    FailedContent,
  },
  computed: {
    _paymentError() {
      return this.$store.state.paymentError;
    },
    isExpiredError() {
      const error = this._paymentError || '';
      // Ensure error is a string before calling toLowerCase
      const errorString = typeof error === 'string' ? error : String(error || '');
      const lowerError = errorString.toLowerCase();

      return lowerError.includes('expired') ||
             lowerError.includes('หมดอายุ') ||
             lowerError.includes('token') ||
             errorString.includes('30');
    },
  },
};
</script>

<style lang="scss" scoped>
.error-icon {
  text-align: center;

  i {
    font-size: 64px;
    color: #dc3545;
  }
}

.error-message {
  margin-top: 16px;
  padding: 20px;
  background: #fff3cd;
  border: 2px solid #ffc107;
  border-radius: 12px;
  color: #856404;

  p {
    margin: 0;
    font-size: 16px;
    line-height: 1.6;
  }
}

.help-text {
  background: #e7f3ff;
  border: 2px solid #2196f3;
  border-radius: 12px;
  padding: 20px;

  h4 {
    color: #1565c0;
    margin: 0 0 12px 0;
    font-size: 16px;
    display: flex;
    align-items: center;

    i {
      color: #ffc107;
    }
  }

  ul {
    margin: 0;
    padding-left: 20px;
    color: #1565c0;

    li {
      margin-bottom: 8px;
      font-size: 14px;
      line-height: 1.6;

      &:last-child {
        margin-bottom: 0;
      }
    }
  }
}
</style>
