<template>
  <div class="layout">
    <sl-alert type="danger" duration="3000" closable ref="errorAlert">
      <sl-icon slot="icon" name="exclamation-octagon"></sl-icon>
      <template v-if="__errorAlert">
        <strong v-html="__errorAlert.title"></strong><br />
        <span v-html="__errorAlert.description"></span>
      </template>
    </sl-alert>

    <sl-alert type="success" duration="3000" closable ref="successAlert">
      <sl-icon slot="icon" name="check2-circle"></sl-icon>
      <template v-if="__successAlert">
        <strong v-html="__successAlert.title"></strong><br />
        <span v-html="__successAlert.description"></span>
      </template>
    </sl-alert>

    <div class="working-branch-bar" v-if="showBranchBar">
      <BranchSelector />
    </div>

    <nuxt />
  </div>
</template>

<script>
export default {
  computed: {
    __errorAlert () {
      return this.$store.state.errorAlert
    },
    __successAlert () {
      return this.$store.state.successAlert
    },
    showBranchBar () {
      if (!this.$store.state.auth || !this.$store.state.auth.loggedIn) return false
      if (this.$route && this.$route.path === '/select-branch') return false
      return true
    }
  },
  watch: {
    __errorAlert (newVal) {
      if (newVal) this.$refs.errorAlert.toast()
    },
    __successAlert (newVal) {
      if (newVal) this.$refs.successAlert.toast()
    }
  }
}
</script>

<style lang="scss" scoped>
.working-branch-bar {
  display: flex;
  justify-content: flex-end;
  background: #063f48;
  padding: 0 15px 10px;
}
</style>
