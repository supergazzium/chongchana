<template>
  <div>
    <AppHeader
      :left="{
        text: 'Back',
        icon: 'chevron-left',
        callback: () => $router.push('/payment'),
      }"
    />
    <AlertToast />
    <div class="container _pdt-32px" v-if="_paymentData">
      <TextHeading title="ยืนยันการชาร์จเงิน" />

      <!-- Verified Customer Badge -->
      <div class="verified-badge _mgt-24px">
        <i class="fas fa-check-circle"></i>
        <span>ยืนยัน QR Code สำเร็จ</span>
      </div>

      <!-- Customer Info -->
      <div class="customer-info _mgt-24px">
        <div class="info-header">
          <i class="fas fa-user-circle"></i>
          <h4>ข้อมูลลูกค้า</h4>
        </div>
        <div class="info-card">
          <div class="info-row">
            <span class="label"><i class="fas fa-user"></i> ชื่อ</span>
            <span class="value">{{ _paymentData.user.username }}</span>
          </div>
          <div class="info-row">
            <span class="label"><i class="fas fa-phone"></i> เบอร์โทร</span>
            <span class="value">{{ _paymentData.user.phoneNumber }}</span>
          </div>
          <div class="info-row balance-row">
            <span class="label"><i class="fas fa-wallet"></i> ยอดเงินคงเหลือ</span>
            <span class="value balance">฿{{ _paymentData.wallet.balance.toFixed(2) }}</span>
          </div>
          <div class="info-row alert-row" v-if="_paymentData.wallet.status !== 'active'">
            <span class="label"><i class="fas fa-exclamation-triangle"></i> สถานะ</span>
            <span class="value status-warning">{{ _paymentData.wallet.status }}</span>
          </div>
        </div>
      </div>

      <sl-form class="form-payment" @sl-submit="onSubmit">
        <sl-input
          name="amount"
          type="number"
          label="Amount (฿)"
          ref="amountInput"
          :value="formData.amount"
          @sl-input="(e) => (formData.amount = e.target.value)"
          min="0.01"
          max="10000"
          step="0.01"
          required
        >
          <span slot="help-text">Enter amount between ฿0.01 - ฿10,000</span>
        </sl-input>
        <br />
        <sl-textarea
          name="description"
          label="Description (Optional)"
          :value="formData.description"
          @sl-input="(e) => (formData.description = e.target.value)"
          rows="3"
        ></sl-textarea>
        <br />
        <v-sl-button
          type="primary"
          class="_dp-b _w-100pct _mgbt-12px"
          submit
          :disabled="pending || _paymentData.wallet.status !== 'active'"
        >
          {{ pending ? 'Processing...' : 'Confirm Payment' }}
        </v-sl-button>
        <v-sl-button
          type="default"
          class="_dp-b _w-100pct"
          @click="$router.push('/payment')"
          :disabled="pending"
        >
          Cancel
        </v-sl-button>
      </sl-form>
    </div>
  </div>
</template>

<script>
import vSlButton from "../../../admin/components/vSlButton.vue";

export default {
  components: { vSlButton },
  middleware: "auth",
  data() {
    return {
      pending: false,
      formData: {
        amount: "",
        description: "",
      },
    };
  },
  computed: {
    _paymentData() {
      return this.$store.state.paymentData;
    },
  },
  methods: {
    async onSubmit(e) {
      if (!this.formData.amount || this.pending) {
        return;
      }

      const amount = parseFloat(this.formData.amount);

      if (isNaN(amount) || amount <= 0) {
        this.__showToast({
          type: "danger",
          title: "Invalid Amount",
          message: "Please enter a valid amount greater than 0",
        });
        return;
      }

      if (amount > this._paymentData.wallet.balance) {
        this.__showToast({
          type: "danger",
          title: "Insufficient Balance",
          message: `Customer balance: ฿${this._paymentData.wallet.balance.toFixed(2)}`,
        });
        return;
      }

      this.pending = true;

      try {
        const payload = {
          nonce: this._paymentData.nonce,
          amount: amount,
          description: this.formData.description || `${this._paymentData.purpose === 'beer_machine' ? 'Beer machine' : 'Store'} payment`,
          metadata: {
            staffId: this.$auth.user.id,
            staffUsername: this.$auth.user.username,
            branch: this.$auth.user.branch,
            timestamp: new Date().toISOString(),
          },
        };

        // Use the public axios instance that completely bypasses authentication
        const response = await this.$publicAxios.post(
          "/wallet/payment-qr/pay",
          payload
        ).then(res => res.data);

        if (response.success && response.data) {
          this.$store.commit("SET_BY_KEY", {
            key: "paymentResult",
            value: {
              ...response.data,
              customerName: this._paymentData.user.username,
              customerPhone: this._paymentData.user.phoneNumber,
            },
          });
          this.$router.push("/payment/success");
        } else {
          this.$store.commit("SET_BY_KEY", {
            key: "paymentError",
            value: response.message || "Payment failed",
          });
          this.$router.push("/payment/failed");
        }
      } catch (e) {
        let message = "Payment processing failed";

        if (e.response && e.response.data) {
          message = e.response.data.message || e.response.data.error?.message || message;
        }

        this.$store.commit("SET_BY_KEY", {
          key: "paymentError",
          value: message,
        });
        this.$router.push("/payment/failed");
      } finally {
        this.pending = false;
      }
    },
  },
  mounted() {
    if (!this._paymentData) {
      this.$router.push("/payment");
    } else {
      // Auto-focus amount input
      setTimeout(() => {
        try {
          this.$refs.amountInput.focus();
        } catch (error) {}
      }, 100);
    }
  },
};
</script>

<style lang="scss" scoped>
.verified-badge {
  background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%);
  border: 2px solid #28a745;
  border-radius: 12px;
  padding: 16px;
  text-align: center;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;

  i {
    font-size: 24px;
    color: #28a745;
  }

  span {
    font-size: 16px;
    font-weight: 700;
    color: #155724;
  }
}

.customer-info {
  margin: 24px 0;

  .info-header {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 12px;
    padding-left: 4px;

    i {
      font-size: 24px;
      color: #1797ad;
    }

    h4 {
      margin: 0;
      font-size: 18px;
      color: #495057;
    }
  }
}

.info-card {
  background: #ffffff;
  border-radius: 12px;
  padding: 20px;
  border: 2px solid #e9ecef;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #f1f3f5;

  &:last-child {
    border-bottom: none;
  }

  &.balance-row {
    background: linear-gradient(135deg, #e8f5f7 0%, #d4eef3 100%);
    margin: 8px -20px;
    padding: 16px 20px;
    border-bottom: none;
    border-top: 2px solid #1797ad;
    border-bottom: 2px solid #1797ad;
  }

  &.alert-row {
    background: #fff3cd;
    margin: 8px -20px 0;
    padding: 12px 20px;
    border-bottom: none;
  }

  .label {
    font-weight: 600;
    color: #6c757d;
    font-size: 14px;
    display: flex;
    align-items: center;
    gap: 8px;

    i {
      font-size: 16px;
      color: #1797ad;
    }
  }

  .value {
    font-weight: 600;
    color: #212529;
    font-size: 15px;

    &.balance {
      font-size: 24px;
      color: #1797ad;
      font-weight: 700;
    }

    &.status-warning {
      color: #dc3545;
      font-weight: 700;
      text-transform: uppercase;
    }
  }
}

.form-payment {
  margin-top: 32px;
  background: #f8f9fa;
  padding: 24px;
  border-radius: 12px;
  border: 2px solid #e9ecef;
}
</style>
