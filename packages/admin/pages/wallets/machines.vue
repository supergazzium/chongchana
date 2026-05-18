<template>
  <div class="wallet-page-container">
    <Breadcrumb :items="breadcrumbs" />
    <WalletSubnav />

    <div class="wallet-page-header">
      <div>
        <h1>Beer Machines</h1>
        <p class="subtitle">
          Map raw machine IDs to friendly names so reports show
          "Sukhumvit – Tap #2" instead of a hash.
        </p>
      </div>
      <div class="header-actions">
        <button @click="openCreateModal()" class="wallet-btn primary">
          <i class="fas fa-plus"></i>
          Add machine
        </button>
      </div>
    </div>

    <div v-if="loading" class="wallet-loading">
      <i class="fas fa-spinner fa-spin"></i>
      <p>Loading machines…</p>
    </div>

    <div v-else>
      <!-- Unmapped machine IDs banner — data-quality nudge -->
      <div v-if="unmapped.length" class="unmapped-banner">
        <div class="banner-main">
          <i class="fas fa-exclamation-circle"></i>
          <div>
            <strong>{{ unmapped.length }} machine ID{{ unmapped.length === 1 ? '' : 's' }} appear in transactions but have no entry below.</strong>
            <p>Click any row to give it a friendly name. Revenue is unaffected — this only changes how the machine is labeled in reports.</p>
          </div>
        </div>
        <div class="unmapped-list">
          <button
            v-for="u in unmapped"
            :key="u.machineId"
            class="unmapped-chip"
            @click="openCreateModal(u.machineId)"
          >
            <code>{{ u.machineId }}</code>
            <span class="unmapped-chip-meta">
              {{ formatInt(u.pours) }} pours · ฿{{ formatNumber(u.revenue) }}
            </span>
          </button>
        </div>
      </div>

      <!-- Machines table -->
      <div class="machines-card">
        <table class="machines-table">
          <thead>
            <tr>
              <th>Machine ID</th>
              <th>Display name</th>
              <th>Branch</th>
              <th>Model</th>
              <th class="num">Lifetime pours</th>
              <th class="num">Lifetime revenue</th>
              <th>Last activity</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="machines.length === 0">
              <td colspan="9" class="empty">
                No machines mapped yet. Add one above, or click an unmapped ID.
              </td>
            </tr>
            <tr v-for="m in machines" :key="m.id" :class="{ inactive: !m.isActive }">
              <td><code class="machine-id">{{ m.id }}</code></td>
              <td>
                <strong>{{ m.displayName }}</strong>
                <div v-if="m.notes" class="machine-notes">{{ m.notes }}</div>
              </td>
              <td>{{ m.branchName || '—' }}</td>
              <td>{{ m.model || '—' }}</td>
              <td class="num">{{ formatInt(m.lifetimePours) }}</td>
              <td class="num"><strong>฿{{ formatNumber(m.lifetimeRevenue) }}</strong></td>
              <td>{{ formatRelativeDate(m.lastActivity) }}</td>
              <td>
                <span :class="['status-pill', m.isActive ? 'active' : 'inactive']">
                  <i :class="m.isActive ? 'fas fa-circle' : 'fas fa-circle-notch'"></i>
                  {{ m.isActive ? 'Active' : 'Inactive' }}
                </span>
              </td>
              <td>
                <div class="row-actions">
                  <button @click="openEditModal(m)" class="wallet-btn secondary tiny">
                    <i class="fas fa-edit"></i>
                    Edit
                  </button>
                  <button
                    v-if="m.isActive"
                    @click="toggleActive(m, false)"
                    class="wallet-btn secondary tiny"
                  >
                    <i class="fas fa-pause"></i>
                    Deactivate
                  </button>
                  <button
                    v-else
                    @click="toggleActive(m, true)"
                    class="wallet-btn success tiny"
                  >
                    <i class="fas fa-play"></i>
                    Reactivate
                  </button>
                  <button @click="deleteMachine(m)" class="wallet-btn danger tiny">
                    <i class="fas fa-trash"></i>
                    Delete
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Add / Edit modal -->
    <div v-if="modalOpen" class="modal-overlay" @click="closeModal">
      <div class="modal-content" @click.stop>
        <h2>
          <i class="fas fa-beer"></i>
          {{ form.isEdit ? 'Edit machine' : 'Add machine' }}
        </h2>

        <div class="modal-body">
          <div class="wallet-filter-item">
            <label>Machine ID *</label>
            <input
              v-model="form.id"
              type="text"
              :disabled="form.isEdit"
              placeholder="e.g. MACHINE-A1B2"
            />
            <p class="hint" v-if="form.isEdit">ID is immutable — it links to historical transactions.</p>
            <p class="hint" v-else>Must match the ID the machine sends. Case-sensitive.</p>
          </div>

          <div class="wallet-filter-item">
            <label>Display name *</label>
            <input
              v-model="form.displayName"
              type="text"
              placeholder="e.g. Sukhumvit 31 – Tap #2"
            />
          </div>

          <div class="wallet-filter-item">
            <label>Branch (declared home)</label>
            <select v-model="form.branchId">
              <option :value="null">— None —</option>
              <option v-for="b in branches" :key="b.id" :value="b.id">{{ b.name }}</option>
            </select>
            <p class="hint">Optional. Reports still attribute revenue using the transaction's branch field.</p>
          </div>

          <div class="wallet-filter-item">
            <label>Model</label>
            <input v-model="form.model" type="text" placeholder="e.g. KegBot-3000" />
          </div>

          <div class="wallet-filter-item">
            <label>Installed at</label>
            <input v-model="form.installedAt" type="date" />
          </div>

          <div class="wallet-filter-item">
            <label>Notes</label>
            <textarea
              v-model="form.notes"
              rows="3"
              placeholder="Anything ops needs to know (service contract, partner-owned, etc.)"
            ></textarea>
          </div>

          <label class="checkbox-row">
            <input type="checkbox" v-model="form.isActive" />
            <span>Active</span>
          </label>

          <div class="modal-actions">
            <button @click="closeModal" class="wallet-btn secondary">Cancel</button>
            <button
              @click="submit"
              class="wallet-btn success"
              :disabled="!canSubmit"
            >
              {{ form.isEdit ? 'Save changes' : 'Add machine' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Breadcrumb from '~/components/Breadcrumb';

export default {
  name: 'WalletMachines',
  middleware: 'auth',
  components: { Breadcrumb },
  data() {
    return {
      breadcrumbs: [
        { label: 'Dashboard', path: '/dashboard' },
        { label: 'Wallet Management', path: '/wallets' },
        { label: 'Beer Machines' },
      ],
      loading: false,
      machines: [],
      unmapped: [],
      branches: [],
      modalOpen: false,
      form: {
        isEdit: false,
        id: '',
        displayName: '',
        branchId: null,
        model: '',
        installedAt: '',
        notes: '',
        isActive: true,
      },
    };
  },
  computed: {
    canSubmit() {
      return (
        this.form.id.trim().length > 0
        && this.form.displayName.trim().length > 0
      );
    },
  },
  async mounted() {
    await Promise.all([this.loadMachines(), this.loadBranches()]);
  },
  methods: {
    async loadMachines() {
      this.loading = true;
      try {
        const response = await this.$walletService.listMachines({ includeUnmapped: '1' });
        if (response.success) {
          this.machines = response.data.machines || [];
          this.unmapped = response.data.unmapped || [];
        }
      } catch (e) {
        this.$swal({ icon: 'error', title: 'Error', text: 'Failed to load machines' });
      } finally {
        this.loading = false;
      }
    },

    async loadBranches() {
      try {
        const branches = await this.$axios.$get('/branches?_limit=-1');
        this.branches = Array.isArray(branches) ? branches : [];
      } catch (e) {
        this.branches = [];
      }
    },

    openCreateModal(prefillId) {
      this.form = {
        isEdit: false,
        id: prefillId || '',
        displayName: '',
        branchId: null,
        model: '',
        installedAt: '',
        notes: '',
        isActive: true,
      };
      this.modalOpen = true;
    },

    openEditModal(machine) {
      this.form = {
        isEdit: true,
        id: machine.id,
        displayName: machine.displayName,
        branchId: machine.branchId || null,
        model: machine.model || '',
        installedAt: machine.installedAt ? this.$moment(machine.installedAt).format('YYYY-MM-DD') : '',
        notes: machine.notes || '',
        isActive: machine.isActive,
      };
      this.modalOpen = true;
    },

    closeModal() {
      this.modalOpen = false;
    },

    async submit() {
      if (!this.canSubmit) return;
      const payload = {
        id: this.form.id.trim(),
        displayName: this.form.displayName.trim(),
        branchId: this.form.branchId || null,
        model: this.form.model || null,
        installedAt: this.form.installedAt || null,
        notes: this.form.notes || null,
        isActive: this.form.isActive,
      };
      try {
        if (this.form.isEdit) {
          await this.$walletService.updateMachine(payload.id, payload);
        } else {
          await this.$walletService.createMachine(payload);
        }
        this.$swal({ icon: 'success', title: 'Saved', timer: 1500, showConfirmButton: false });
        this.closeModal();
        this.loadMachines();
      } catch (e) {
        this.$swal({
          icon: 'error',
          title: 'Error',
          text: e.response?.data?.error?.message || 'Failed to save',
        });
      }
    },

    async toggleActive(machine, makeActive) {
      try {
        await this.$walletService.updateMachine(machine.id, { isActive: makeActive });
        this.loadMachines();
      } catch (e) {
        this.$swal({ icon: 'error', title: 'Error', text: 'Failed to update status' });
      }
    },

    async deleteMachine(machine) {
      const result = await this.$swal({
        icon: 'warning',
        title: 'Delete machine mapping?',
        html: `<p>Delete <strong>${machine.displayName}</strong> (<code>${machine.id}</code>)?</p>
               <p>Transactions are not affected — only the friendly name mapping is removed.</p>`,
        showCancelButton: true,
        confirmButtonText: 'Delete',
        confirmButtonColor: '#cb2731',
      });
      if (!result.isConfirmed) return;
      try {
        await this.$walletService.deleteMachine(machine.id);
        this.loadMachines();
      } catch (e) {
        this.$swal({ icon: 'error', title: 'Error', text: 'Failed to delete' });
      }
    },

    formatNumber(value) {
      if (value === null || value === undefined) return '0.00';
      return parseFloat(value).toLocaleString('en-US', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      });
    },

    formatInt(value) {
      if (value === null || value === undefined) return '0';
      return parseInt(value, 10).toLocaleString('en-US');
    },

    formatRelativeDate(date) {
      if (!date) return '—';
      return this.$moment(date).tz('Asia/Bangkok').fromNow();
    },
  },
};
</script>

<style scoped>
.unmapped-banner {
  background: rgba(245, 158, 11, 0.08);
  border: 1px solid #F59E0B;
  border-radius: 12px;
  padding: 16px;
  margin-bottom: 20px;
}

.banner-main {
  display: flex;
  gap: 12px;
  align-items: flex-start;
  margin-bottom: 12px;
}

.banner-main i {
  font-size: 20px;
  color: #B45309;
  margin-top: 2px;
}

.banner-main strong {
  display: block;
  color: #92400E;
  margin-bottom: 4px;
}

.banner-main p {
  margin: 0;
  font-size: 13px;
  color: #78350F;
}

.unmapped-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.unmapped-chip {
  display: inline-flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 2px;
  padding: 8px 12px;
  background: #fff;
  border: 1px solid #F59E0B;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.12s ease;
}

.unmapped-chip:hover {
  background: #FEF3C7;
}

.unmapped-chip code {
  font-family: 'SF Mono', Menlo, Consolas, monospace;
  font-size: 12px;
  color: #92400E;
  font-weight: 600;
}

.unmapped-chip-meta {
  font-size: 11px;
  color: #78350F;
}

.machines-card {
  background: #fff;
  border-radius: 16px;
  border: 1px solid #E2E8F0;
  overflow-x: auto;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
}

.machines-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  font-variant-numeric: tabular-nums;
}

.machines-table thead th {
  text-align: left;
  padding: 12px;
  background: #F7FAFC;
  font-weight: 600;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: #6B7280;
  border-bottom: 1px solid #E5E7EB;
  white-space: nowrap;
}

.machines-table th.num,
.machines-table td.num {
  text-align: right;
}

.machines-table tbody td {
  padding: 12px;
  border-bottom: 1px solid #F1F5F9;
  color: #1F2937;
  vertical-align: top;
}

.machines-table tbody tr.inactive {
  opacity: 0.55;
}

.machines-table tbody tr:hover td {
  background: #F9FAFB;
}

.machines-table .empty {
  text-align: center;
  padding: 40px;
  color: #9CA3AF;
}

.machine-id {
  font-family: 'SF Mono', Menlo, Consolas, monospace;
  font-size: 12px;
  padding: 2px 8px;
  background: #F1F5F9;
  border-radius: 6px;
  color: #0F172A;
}

.machine-notes {
  font-size: 11px;
  color: #6B7280;
  margin-top: 4px;
}

.status-pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 3px 10px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 600;
}

.status-pill.active {
  background: rgba(0, 168, 98, 0.12);
  color: #00794a;
}

.status-pill.inactive {
  background: rgba(107, 114, 128, 0.12);
  color: #4B5563;
}

.status-pill i {
  font-size: 8px;
}

.row-actions {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}

.wallet-btn.tiny {
  padding: 4px 10px;
  font-size: 11px;
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: #fff;
  border-radius: 16px;
  padding: 28px;
  max-width: 560px;
  width: 92%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.modal-content h2 {
  margin: 0 0 20px;
  font-size: 20px;
  color: #063F48;
}

.modal-content h2 i {
  margin-right: 8px;
  color: #F59E0B;
}

.modal-body .wallet-filter-item {
  margin-bottom: 16px;
}

.hint {
  margin: 4px 0 0;
  font-size: 11px;
  color: #9CA3AF;
}

.checkbox-row {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 20px;
  font-weight: 600;
  color: #1F2937;
  cursor: pointer;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

textarea {
  width: 100%;
  padding: 10px 14px;
  border: 2px solid #E2E8F0;
  border-radius: 12px;
  font-size: 14px;
  font-family: inherit;
  resize: vertical;
}
</style>
