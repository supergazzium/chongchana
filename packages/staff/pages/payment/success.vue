<template>
  <div>
    <AppHeader />
    <div class="container _pdt-32px" v-if="_paymentResult">
      <SuccessContent
        title="ชาร์จเงินสำเร็จ"
        :back="{
          label: 'Back to Payment Scanner',
          path: '/payment',
        }"
      >
        <template #remark>
          <p class="_tal-ct">
            Transaction ID:
            <span class="transaction-id" v-html="_paymentResult.transactionId"></span>
          </p>
          <p class="_tal-ct">
            <span v-html="$moment(_paymentResult.timestamp).format('YYYY-MM-DD HH:mm:ss')"></span>
          </p>
        </template>

        <template #content>
          <div class="payment-details">
            <div class="detail-row">
              <span class="label">Customer:</span>
              <span class="value">{{ _paymentResult.customerName }}</span>
            </div>
            <div class="detail-row">
              <span class="label">Phone:</span>
              <span class="value">{{ _paymentResult.customerPhone }}</span>
            </div>
            <div class="detail-row amount-row">
              <span class="label">Amount Charged:</span>
              <span class="value amount">฿{{ Number(_paymentResult.amount).toFixed(2) }}</span>
            </div>
            <div class="detail-row">
              <span class="label">Previous Balance:</span>
              <span class="value">฿{{ Number(_paymentResult.oldBalance).toFixed(2) }}</span>
            </div>
            <div class="detail-row">
              <span class="label">New Balance:</span>
              <span class="value balance">฿{{ Number(_paymentResult.newBalance).toFixed(2) }}</span>
            </div>
          </div>
        </template>
      </SuccessContent>
    </div>
  </div>
</template>

<script>
import SuccessContent from "~/components/SuccessContent";

export default {
  middleware: "auth",
  components: {
    SuccessContent,
  },
  computed: {
    _paymentResult() {
      return this.$store.state.paymentResult;
    },
  },
  mounted() {
    if (!this._paymentResult) {
      this.$router.push("/payment");
    }
  },
};
</script>

<style lang="scss" scoped>
.transaction-id {
  font-family: monospace;
  font-size: 0.9em;
  color: #6c757d;
}

.payment-details {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 20px;
  margin-top: 16px;
  border: 1px solid #e9ecef;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 0;
  border-bottom: 1px solid #e9ecef;

  &:last-child {
    border-bottom: none;
  }

  &.amount-row {
    margin: 8px 0;
    padding: 16px 0;
    border-top: 2px solid #1797ad;
    border-bottom: 2px solid #1797ad;
  }

  .label {
    font-weight: 600;
    color: #6c757d;
  }

  .value {
    font-weight: 500;
    color: #212529;

    &.amount {
      font-size: 1.3em;
      color: #dc3545;
      font-weight: 700;
    }

    &.balance {
      font-size: 1.1em;
      color: #1797ad;
      font-weight: 700;
    }
  }
}
</style>
