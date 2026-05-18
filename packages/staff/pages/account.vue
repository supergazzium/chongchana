<template>
  <div>
    <AppHeader />
    <TextHeading title="Staff" class="_mgt-32px _mgbt-48px" />
    <!-- <ProfileImage class="_mgt-32px _mgbt-48px" /> -->

    <div class="setting-items-wrapper" v-if="_user">
      <div class="setting-item -no-hover" :class="{ '-active': $route.path === '/account/email' }">
        <h4>Name</h4>
        <div class="_dp-f _alit-ct">
          <p v-html="_user.nickname"></p>
          <!-- <i class="far fa-chevron-right _mgl-12px"></i> -->
        </div>
      </div>

      <div class="setting-item -no-hover" :class="{ '-active': $route.path === '/account/email' }">
        <h4>Email</h4>
        <div class="_dp-f _alit-ct">
          <p v-html="_user.email"></p>
        </div>
      </div>

      <div class="setting-item -no-hover" :class="{ '-active': $route.path === '/account/email' }">
        <h4>Home Branch</h4>
        <div class="_dp-f _alit-ct">
          <p v-html="_user.branch ? _user.branch.name : '-'"></p>
        </div>
      </div>

      <div
        class="setting-item working-branch-row -no-hover"
        :class="{ 'is-away': _awayFromHome }"
      >
        <h4>Working At</h4>
        <div class="_dp-f _alit-ct working-branch-action">
          <p>
            {{ _workingBranch ? _workingBranch.name : 'Not selected' }}
            <span class="away-tag" v-if="_awayFromHome">away</span>
          </p>
          <button type="button" class="change-branch-btn" @click="changeBranch">
            <i class="fas fa-exchange-alt"></i>
            Change
          </button>
        </div>
      </div>
    </div>

    <div class="container _mgt-32px">
      <div class="row">
        <div class="col-6 _pdr-8px">
          <v-sl-button type="primary" href="/scanner" class="_dp-b _w-100pct _mgbt-12px">
            <i class="fas fa-qrcode _opct-70 _mgr-8px"></i>
            <span>แสกนเข้าร้าน</span>
          </v-sl-button>
        </div>
        <div class="col-6 _pdl-8px">
          <v-sl-button type="primary" href="/points" class="_dp-b _w-100pct _mgbt-12px">
            <i class="fas fa-star _opct-70 _mgr-8px"></i>
            <span>หัก Point</span>
          </v-sl-button>
        </div>
        <div class="col-12">
          <v-sl-button type="primary" href="/payment" class="_dp-b _w-100pct _mgbt-12px">
            <i class="fas fa-wallet _opct-70 _mgr-8px"></i>
            <span>ชาร์จเงินกระเป๋า</span>
          </v-sl-button>
        </div>
        <div class="col-12">
          <v-sl-button type="primary" href="/bookings" class="_dp-b _w-100pct">
            <i class="fas fa-ticket _opct-70 _mgr-8px"></i>
            <span>รายการจองวันนี้</span>
          </v-sl-button>
        </div>
        <div class="col-12 _mgt-4px">
          <v-sl-button type="primary" href="/event-bookings" class="_dp-b _w-100pct">
            <i class="fas fa-music _opct-70 _mgr-8px"></i>
            <span>Event Booking</span>
          </v-sl-button>
        </div>
      </div>
    </div>

    <button class="logout _mgt-32px" @click="signout">
      <span>ออกจากระบบ</span>
    </button>
  </div>
</template>

<script>
import ProfileImage from '~/components/ProfileImage'

export default {
  middleware: 'auth',
  components: {
    ProfileImage,
  },
  computed: {
    _user() {
      if (this.$store.state.auth) {
        if (this.$store.state.auth.user) return this.$store.state.auth.user
      }
    },
    _workingBranch() {
      return this.$store.state.workingBranch
    },
    _awayFromHome() {
      return this.$store.getters.isWorkingAwayFromHome
    },
  },
  methods: {
    changeBranch() {
      this.$router.push(
        `/select-branch?redirect=${encodeURIComponent('/account')}`
      )
    },
    async signout() {
      this.__toastAlert('success', {
        title: 'Signout Successfully',
        description: 'Successfully signing you out',
      })
      setTimeout(async () => await this.$auth.logout(), 1000)
    },
  },
}
</script>

<style lang="scss" scoped>
.setting-items-wrapper {
  .setting-item {
    border-top: 1px solid #e2e2e2;
    padding-top: 12px;
    padding-bottom: 12px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-left: 32px;
    padding-right: 32px;
    transition: 0.3s;
    cursor: pointer;

    &.-no-hover {
      cursor: default;

      &:hover {
        background: transparent;
        transition: 0.3s;
      }
    }

    &.-active {
      background: rgba(#1797ad, 0.08);
      transition: 0.3s;
    }

    &:hover {
      background: rgba(#1797ad, 0.08);
      transition: 0.3s;
    }

    p {
      color: #666;
    }

    &:last-of-type {
      border-bottom: 1px solid #e2e2e2;
    }
  }
}

.logout {
  display: block;
  text-align: center;
  font-weight: bold;
  font-size: 16px;
  color: #cb2731;
  background: transparent;
  border: none;
  width: 100%;
}

.working-branch-row {
  background: rgba(#1797ad, 0.04);

  &.is-away {
    background: rgba(#f59e0b, 0.1);

    p {
      color: #b45309;
      font-weight: 600;
    }
  }

  h4 {
    color: #063f48;
  }
}

.working-branch-action {
  gap: 12px;
}

.away-tag {
  display: inline-block;
  margin-left: 6px;
  padding: 2px 8px;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: #fff;
  background: #f59e0b;
  border-radius: 999px;
  vertical-align: middle;
}

.change-branch-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  border: 1.5px solid #1797ad;
  background: #fff;
  color: #1797ad;
  font-size: 13px;
  font-weight: 600;
  border-radius: 999px;
  cursor: pointer;
  transition: background 0.15s ease, color 0.15s ease;

  &:hover {
    background: #1797ad;
    color: #fff;
  }

  i {
    font-size: 12px;
  }
}

.working-branch-row.is-away .change-branch-btn {
  border-color: #f59e0b;
  color: #b45309;

  &:hover {
    background: #f59e0b;
    color: #fff;
  }
}
</style>