<template>
  <div class="branch-selector" v-if="loggedIn">
    <button
      type="button"
      class="branch-pill"
      :class="{ 'is-away': awayFromHome }"
      @click="openModal"
    >
      <i class="fas fa-map-marker-alt"></i>
      <span class="pill-text">
        {{ workingBranch ? workingBranch.name : 'Select branch' }}
      </span>
      <i class="fas fa-chevron-down chev"></i>
    </button>

    <div v-if="modalOpen" class="bs-overlay" @click.self="closeModal">
      <div class="bs-sheet">
        <div class="bs-header">
          <h3>Where are you working?</h3>
          <button class="bs-close" @click="closeModal" aria-label="Close">
            <i class="fas fa-times"></i>
          </button>
        </div>

        <p class="bs-help">
          Charges will be attributed to the branch you select below.
        </p>

        <div class="bs-list">
          <div v-if="loading" class="bs-loading">
            <i class="fas fa-spinner fa-spin"></i>
            Loading branches…
          </div>
          <button
            v-for="branch in sortedBranches"
            :key="branch.id"
            type="button"
            class="bs-item"
            :class="{
              active: workingBranch && workingBranch.id === branch.id,
              home: homeBranch && homeBranch.id === branch.id,
            }"
            @click="pick(branch)"
          >
            <div class="bs-item-main">
              <span class="bs-item-name">{{ branch.name }}</span>
              <span class="bs-item-tag" v-if="homeBranch && homeBranch.id === branch.id">
                your branch
              </span>
            </div>
            <i
              v-if="workingBranch && workingBranch.id === branch.id"
              class="fas fa-check bs-check"
            ></i>
          </button>
          <div v-if="!loading && sortedBranches.length === 0" class="bs-empty">
            No branches available.
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'BranchSelector',
  data() {
    return {
      modalOpen: false,
      loading: false,
    };
  },
  computed: {
    loggedIn() {
      return this.$store.state.auth && this.$store.state.auth.loggedIn;
    },
    workingBranch() {
      return this.$store.state.workingBranch;
    },
    branches() {
      return this.$store.state.branches;
    },
    homeBranch() {
      return this.$store.getters.homeBranch;
    },
    awayFromHome() {
      return this.$store.getters.isWorkingAwayFromHome;
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
  methods: {
    async openModal() {
      this.modalOpen = true;
      if (!this.branches || this.branches.length === 0) {
        this.loading = true;
        try {
          await this.$store.dispatch('fetchBranches');
        } finally {
          this.loading = false;
        }
      }
    },
    closeModal() {
      this.modalOpen = false;
    },
    pick(branch) {
      const wasAway =
        this.homeBranch && branch.id !== this.homeBranch.id;
      this.$store.dispatch('setWorkingBranch', {
        id: branch.id,
        name: branch.name,
      });
      this.closeModal();
      if (wasAway) {
        this.$store.commit('SET_BY_KEY', {
          key: 'successAlert',
          value: {
            title: `Working at ${branch.name}`,
            description:
              'All charges will be attributed to this branch until you change it.',
          },
        });
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.branch-selector {
  display: inline-flex;
}

.branch-pill {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: rgba(255, 255, 255, 0.12);
  color: #fff;
  border: 1px solid rgba(255, 255, 255, 0.25);
  border-radius: 999px;
  padding: 6px 14px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  max-width: 220px;
  transition: background 0.15s ease, border-color 0.15s ease;

  .pill-text {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .chev {
    font-size: 10px;
    opacity: 0.85;
  }

  &:hover {
    background: rgba(255, 255, 255, 0.2);
  }

  &.is-away {
    background: #f59e0b;
    border-color: #d97706;
    color: #1f2937;
  }
}

.bs-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: flex-end;
  justify-content: center;
  z-index: 9999;
}

.bs-sheet {
  background: #fff;
  width: 100%;
  max-width: 480px;
  border-top-left-radius: 20px;
  border-top-right-radius: 20px;
  padding: 20px 20px 28px;
  max-height: 80vh;
  display: flex;
  flex-direction: column;
}

.bs-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 4px;

  h3 {
    margin: 0;
    font-size: 18px;
    color: #063f48;
  }

  .bs-close {
    background: transparent;
    border: none;
    font-size: 18px;
    color: #6b7280;
    cursor: pointer;
    padding: 4px 8px;
  }
}

.bs-help {
  margin: 0 0 16px;
  font-size: 13px;
  color: #6b7280;
}

.bs-list {
  overflow-y: auto;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.bs-loading,
.bs-empty {
  padding: 24px;
  text-align: center;
  color: #6b7280;
  font-size: 14px;

  i {
    margin-right: 8px;
  }
}

.bs-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #f9fafb;
  border: 2px solid transparent;
  border-radius: 12px;
  padding: 14px 16px;
  cursor: pointer;
  text-align: left;
  transition: background 0.12s ease, border-color 0.12s ease;

  &:hover {
    background: #f3f4f6;
  }

  &.active {
    background: #e0f2f5;
    border-color: #1797ad;
  }

  &.home .bs-item-tag {
    background: #1797ad;
    color: #fff;
  }
}

.bs-item-main {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.bs-item-name {
  font-size: 15px;
  font-weight: 600;
  color: #111827;
}

.bs-item-tag {
  display: inline-block;
  width: fit-content;
  background: #e5e7eb;
  color: #374151;
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 999px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.bs-check {
  color: #1797ad;
  font-size: 16px;
}
</style>
