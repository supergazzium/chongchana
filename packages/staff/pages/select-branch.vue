<template>
  <div class="select-branch-page">
    <AppHeader />
    <AlertToast />

    <div class="container _pdt-32px">
      <div class="hero">
        <i class="fas fa-map-marker-alt hero-icon"></i>
        <h2>Where are you working today?</h2>
        <p class="hero-sub">
          Pick the branch you are physically working at right now. All charges
          you process will be attributed to this branch.
        </p>
      </div>

      <div class="branch-list" v-if="!loading">
        <button
          v-for="branch in sortedBranches"
          :key="branch.id"
          type="button"
          class="branch-card"
          :class="{ home: isHome(branch) }"
          @click="select(branch)"
        >
          <div class="card-main">
            <div class="card-name">{{ branch.name }}</div>
            <div class="card-tag" v-if="isHome(branch)">your branch</div>
          </div>
          <i class="fas fa-chevron-right card-chev"></i>
        </button>

        <div v-if="sortedBranches.length === 0" class="empty">
          <i class="fas fa-exclamation-circle"></i>
          <p>No branches available. Contact your administrator.</p>
        </div>
      </div>

      <div v-else class="loading">
        <i class="fas fa-spinner fa-spin"></i>
        Loading branches…
      </div>
    </div>
  </div>
</template>

<script>
export default {
  middleware: 'auth',
  data() {
    return {
      loading: true,
    };
  },
  computed: {
    branches() {
      return this.$store.state.branches;
    },
    homeBranch() {
      return this.$store.getters.homeBranch;
    },
    sortedBranches() {
      const list = (this.branches || []).slice();
      const homeId = this.homeBranch && this.homeBranch.id;
      list.sort((a, b) => {
        if (homeId) {
          if (a.id === homeId) return -1;
          if (b.id === homeId) return 1;
        }
        return (a.name || '').localeCompare(b.name || '');
      });
      return list;
    },
  },
  async mounted() {
    if (!this.branches || this.branches.length === 0) {
      await this.$store.dispatch('fetchBranches');
    }
    this.loading = false;
  },
  methods: {
    isHome(branch) {
      return this.homeBranch && this.homeBranch.id === branch.id;
    },
    select(branch) {
      this.$store.dispatch('setWorkingBranch', {
        id: branch.id,
        name: branch.name,
      });

      if (!this.isHome(branch)) {
        this.$store.commit('SET_BY_KEY', {
          key: 'successAlert',
          value: {
            title: `Working at ${branch.name}`,
            description: 'You can change this anytime from the header.',
          },
        });
      }

      const redirect = this.$route.query.redirect || '/account';
      this.$router.replace(redirect);
    },
  },
};
</script>

<style lang="scss" scoped>
.select-branch-page {
  min-height: 100vh;
  background: #f8fafc;
}

.hero {
  text-align: center;
  margin-top: 8px;
  margin-bottom: 28px;
}

.hero-icon {
  font-size: 36px;
  color: #1797ad;
  margin-bottom: 12px;
}

.hero h2 {
  margin: 0 0 8px;
  font-size: 22px;
  color: #063f48;
}

.hero-sub {
  margin: 0 auto;
  max-width: 380px;
  font-size: 14px;
  line-height: 1.5;
  color: #4b5563;
}

.branch-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-width: 480px;
  margin: 0 auto;
}

.branch-card {
  background: #fff;
  border: 2px solid #e5e7eb;
  border-radius: 14px;
  padding: 18px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  cursor: pointer;
  text-align: left;
  transition: border-color 0.15s ease, box-shadow 0.15s ease,
    transform 0.05s ease;

  &:hover {
    border-color: #1797ad;
    box-shadow: 0 4px 12px rgba(23, 151, 173, 0.12);
  }

  &:active {
    transform: scale(0.99);
  }

  &.home {
    border-color: #1797ad;
    background: linear-gradient(135deg, #f0f9fa 0%, #e0f2f5 100%);
  }
}

.card-main {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.card-name {
  font-size: 16px;
  font-weight: 700;
  color: #111827;
}

.card-tag {
  display: inline-block;
  width: fit-content;
  background: #1797ad;
  color: #fff;
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 999px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.card-chev {
  color: #9ca3af;
  font-size: 14px;
}

.loading,
.empty {
  text-align: center;
  padding: 32px;
  color: #6b7280;

  i {
    margin-right: 8px;
  }

  p {
    margin-top: 12px;
  }
}
</style>
