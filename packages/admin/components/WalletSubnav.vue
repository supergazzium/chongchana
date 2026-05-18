<template>
  <nav class="wallet-subnav" aria-label="Wallet section">
    <nuxt-link
      v-for="tab in tabs"
      :key="tab.path"
      :to="tab.path"
      :class="['wallet-subnav-tab', { active: isActive(tab) }]"
    >
      <i :class="['fas', `fa-${tab.icon}`]"></i>
      <span>{{ tab.label }}</span>
    </nuxt-link>
  </nav>
</template>

<script>
// Section nav for /wallets/*. Single source of truth for tab order
// and active matching. To add a tab, edit this list and create the
// page — every wallet page picks it up automatically.
const TABS = [
  { path: '/wallets',              label: 'Overview',     icon: 'wallet' },
  { path: '/wallets/transactions', label: 'Transactions', icon: 'list' },
  { path: '/wallets/reports',      label: 'Reports',      icon: 'chart-bar' },
  { path: '/wallets/machines',     label: 'Machines',     icon: 'beer' },
  { path: '/wallets/vouchers',     label: 'Vouchers',     icon: 'gift' },
  { path: '/wallets/settings',     label: 'Settings',     icon: 'cog' },
];

export default {
  name: 'WalletSubnav',
  data() {
    return { tabs: TABS };
  },
  methods: {
    // The Overview tab matches exactly so child pages don't all
    // light it up. All others match on prefix so detail pages
    // (e.g. /wallets/transactions/123) still highlight their tab.
    isActive(tab) {
      const path = this.$route.path;
      if (tab.path === '/wallets') {
        // Wallet detail pages (/wallets/:userId) belong under Overview.
        // Subsection pages (/wallets/transactions, /wallets/reports...)
        // do not.
        if (path === '/wallets') return true;
        const subsectionRoots = this.tabs
          .filter((t) => t.path !== '/wallets')
          .map((t) => t.path);
        return subsectionRoots.every((root) => !path.startsWith(root));
      }
      return path === tab.path || path.startsWith(`${tab.path}/`);
    },
  },
};
</script>

<style lang="scss" scoped>
.wallet-subnav {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-bottom: 20px;
  padding: 6px;
  background: #fff;
  border: 1px solid #E2E8F0;
  border-radius: 12px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03);
}

.wallet-subnav-tab {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  color: #6B7280;
  text-decoration: none;
  transition: background 0.12s ease, color 0.12s ease;

  i {
    font-size: 12px;
    opacity: 0.75;
  }

  &:hover {
    background: rgba(23, 151, 173, 0.08);
    color: #1797AD;
  }

  &.active {
    background: #1797AD;
    color: #fff;
    box-shadow: 0 2px 6px rgba(23, 151, 173, 0.3);

    i {
      opacity: 1;
    }
  }
}

@media (max-width: 768px) {
  .wallet-subnav {
    overflow-x: auto;
    flex-wrap: nowrap;
    -webkit-overflow-scrolling: touch;
  }

  .wallet-subnav-tab {
    flex-shrink: 0;
  }
}

@media print {
  .wallet-subnav {
    display: none !important;
  }
}
</style>
