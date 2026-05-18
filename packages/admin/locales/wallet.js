// Wallet section translations.
// Keep keys flat and stable — the wallet pages look up strings by key.
// New keys: add to BOTH en and th. Missing th keys fall back to en.

const en = {
  // page header
  walletOverview: 'Wallet Overview',
  pageSubtitle: 'Top-ups, bonuses, branch revenue, and outstanding float',
  export: 'Export',
  more: 'More',
  navTransactions: 'All Transactions',
  navReports: 'Reports',
  navVouchers: 'Vouchers',
  navSettings: 'Settings',

  // period control
  periodToday: 'Today',
  period7d: '7d',
  periodMtd: 'This Month',
  period30d: '30d',
  periodCustom: 'Custom',

  // KPI cards
  kpiTopUp: 'Total Top-Up',
  kpiTopUpHint: '{count} top-ups · {period}',
  kpiBonus: 'Bonus & Promotion',
  kpiBonusHint: '{count} bonuses · {period}',
  kpiSpend: 'Total Spend',
  kpiSpendHint: '{count} payments · {period}',
  kpiFloat: 'Wallet Float',
  kpiFloatHint: 'Outstanding liability · {count} wallets',
  kpiCtaTransactions: 'View transactions',
  kpiCtaWallets: 'View wallets',

  // branch breakdown
  branchTitle: 'Spend by Branch',
  branchSubtitle: 'How much customers spent at each location · {period}',
  branchTotal: 'Total',
  branchLoading: 'Loading branch data…',
  branchEmpty: 'No branch spend recorded for this period.',
  branchUnattributed: 'Unattributed',
  branchUnattributedTag: 'no branch recorded',
  branchUnattributedHint: 'These spend transactions have no branch attribution — usually legacy data or vending sessions without a branch. They are still counted in Total Spend.',
  branchTransactions: '{count} transactions',
  branchAvg: 'Avg ฿{value}',
  branchShareOfTotal: '{percent}% of total',

  // wallet ops section
  walletsTitle: 'Wallets',
  walletsSubtitle: '{active} active · {frozen} frozen · {suspended} suspended · ฿{pending} pending',

  // filter chips
  filterAll: 'All Wallets',
  filterActive: 'Active',
  filterFrozen: 'Frozen',
  filterSuspended: 'Suspended',
  filterReset: 'Reset',

  // advanced filters
  filterSearch: 'Search',
  filterSearchPlaceholder: 'Name, email, phone, or user ID...',
  filterMinBalance: 'Min Balance',
  filterMaxBalance: 'Max Balance',

  // table headers
  thUserId: 'User ID',
  thName: 'Name',
  thEmail: 'Email',
  thBalance: 'Balance',
  thPending: 'Pending',
  thStatus: 'Status',
  thLastTransaction: 'Last Transaction',
  thActions: 'Actions',

  // empty / loading
  loadingWallets: 'Loading wallets...',
  noWalletsFound: 'No wallets found',

  // actions
  view: 'View',
  adjust: 'Adjust',
  freeze: 'Freeze',
  unfreeze: 'Unfreeze',

  // pagination
  paginationShowing: 'Showing {from} - {to} of {total}',
  previous: 'Previous',
  next: 'Next',

  // adjust modal
  adjustTitle: 'Adjust Wallet Balance',
  adjustUser: 'User',
  adjustCurrentBalance: 'Current Balance',
  adjustType: 'Adjustment Type',
  adjustCredit: 'Credit (Add Money)',
  adjustDebit: 'Debit (Deduct Money)',
  adjustAmount: 'Amount (฿)',
  adjustAmountPlaceholder: 'Enter amount...',
  adjustReason: 'Reason (Required)',
  adjustReasonPlaceholder: 'Enter reason for adjustment...',
  cancel: 'Cancel',
  adjustBalance: 'Adjust Balance',

  // misc
  never: 'Never',

  // transactions page
  txTitle: 'Transactions',
  txTotal: '{count} total',
  txFilters: 'Filters',
  txCompleted: 'Completed',
  txPending: 'Pending',
  txFailed: 'Failed',
  txTotalVolume: 'Total Volume',
  txDashboardBannerPrefix: 'Showing',
  txDashboardBannerType: '{type} transactions',
  txDashboardBannerBranch: ' at {branch}',
  txDashboardBannerPeriod: ' for {period}',
  txClearFilter: 'Clear filter',

  // language toggle
  langToggle: 'ภาษาไทย',
};

const th = {
  walletOverview: 'ภาพรวมกระเป๋าเงิน',
  pageSubtitle: 'การเติมเงิน โบนัส รายได้แต่ละสาขา และยอดคงค้างในระบบ',
  export: 'ส่งออก',
  more: 'เพิ่มเติม',
  navTransactions: 'ธุรกรรมทั้งหมด',
  navReports: 'รายงาน',
  navVouchers: 'คูปอง',
  navSettings: 'ตั้งค่า',

  periodToday: 'วันนี้',
  period7d: '7 วัน',
  periodMtd: 'เดือนนี้',
  period30d: '30 วัน',
  periodCustom: 'กำหนดเอง',

  kpiTopUp: 'ยอดเติมเงินทั้งหมด',
  kpiTopUpHint: 'เติมเงิน {count} ครั้ง · {period}',
  kpiBonus: 'โบนัสและโปรโมชั่น',
  kpiBonusHint: 'รับโบนัส {count} ครั้ง · {period}',
  kpiSpend: 'ยอดใช้จ่ายทั้งหมด',
  kpiSpendHint: 'ชำระเงิน {count} ครั้ง · {period}',
  kpiFloat: 'ยอดเงินคงเหลือในระบบ',
  kpiFloatHint: 'หนี้สินคงค้าง · {count} กระเป๋า',
  kpiCtaTransactions: 'ดูธุรกรรม',
  kpiCtaWallets: 'ดูกระเป๋าเงิน',

  branchTitle: 'ยอดใช้จ่ายแยกตามสาขา',
  branchSubtitle: 'ลูกค้าใช้จ่ายที่แต่ละสาขาเท่าไหร่ · {period}',
  branchTotal: 'รวม',
  branchLoading: 'กำลังโหลดข้อมูลสาขา…',
  branchEmpty: 'ไม่มีข้อมูลการใช้จ่ายในช่วงเวลานี้',
  branchUnattributed: 'ไม่ระบุสาขา',
  branchUnattributedTag: 'ไม่มีข้อมูลสาขา',
  branchUnattributedHint: 'ธุรกรรมเหล่านี้ไม่มีการระบุสาขา โดยส่วนใหญ่เป็นข้อมูลเก่าหรือเซสชั่นตู้กดเบียร์ที่ไม่ระบุสาขา ยังคงนับรวมในยอดใช้จ่ายทั้งหมด',
  branchTransactions: '{count} ธุรกรรม',
  branchAvg: 'เฉลี่ย ฿{value}',
  branchShareOfTotal: '{percent}% ของทั้งหมด',

  walletsTitle: 'กระเป๋าเงิน',
  walletsSubtitle: 'ใช้งาน {active} · ระงับ {frozen} · ถูกพักการใช้งาน {suspended} · รอดำเนินการ ฿{pending}',

  filterAll: 'กระเป๋าทั้งหมด',
  filterActive: 'ใช้งานอยู่',
  filterFrozen: 'ถูกระงับ',
  filterSuspended: 'ถูกพักการใช้งาน',
  filterReset: 'รีเซ็ต',

  filterSearch: 'ค้นหา',
  filterSearchPlaceholder: 'ชื่อ อีเมล เบอร์โทร หรือรหัสผู้ใช้...',
  filterMinBalance: 'ยอดขั้นต่ำ',
  filterMaxBalance: 'ยอดสูงสุด',

  thUserId: 'รหัสผู้ใช้',
  thName: 'ชื่อ',
  thEmail: 'อีเมล',
  thBalance: 'ยอดเงิน',
  thPending: 'รอดำเนินการ',
  thStatus: 'สถานะ',
  thLastTransaction: 'ธุรกรรมล่าสุด',
  thActions: 'จัดการ',

  loadingWallets: 'กำลังโหลดข้อมูลกระเป๋า...',
  noWalletsFound: 'ไม่พบกระเป๋าเงิน',

  view: 'ดู',
  adjust: 'ปรับยอด',
  freeze: 'ระงับ',
  unfreeze: 'ปลดระงับ',

  paginationShowing: 'แสดง {from} - {to} จาก {total}',
  previous: 'ก่อนหน้า',
  next: 'ถัดไป',

  adjustTitle: 'ปรับยอดเงินในกระเป๋า',
  adjustUser: 'ผู้ใช้',
  adjustCurrentBalance: 'ยอดเงินปัจจุบัน',
  adjustType: 'ประเภทการปรับยอด',
  adjustCredit: 'เพิ่มเงิน (Credit)',
  adjustDebit: 'หักเงิน (Debit)',
  adjustAmount: 'จำนวนเงิน (฿)',
  adjustAmountPlaceholder: 'ใส่จำนวนเงิน...',
  adjustReason: 'เหตุผล (จำเป็นต้องระบุ)',
  adjustReasonPlaceholder: 'ใส่เหตุผลในการปรับยอด...',
  cancel: 'ยกเลิก',
  adjustBalance: 'ปรับยอดเงิน',

  never: 'ไม่เคย',

  txTitle: 'ธุรกรรม',
  txTotal: 'ทั้งหมด {count} รายการ',
  txFilters: 'ตัวกรอง',
  txCompleted: 'สำเร็จ',
  txPending: 'รอดำเนินการ',
  txFailed: 'ล้มเหลว',
  txTotalVolume: 'ยอดรวม',
  txDashboardBannerPrefix: 'กำลังแสดง',
  txDashboardBannerType: 'ธุรกรรม{type}',
  txDashboardBannerBranch: ' ที่ {branch}',
  txDashboardBannerPeriod: ' ในช่วง {period}',
  txClearFilter: 'ล้างตัวกรอง',

  langToggle: 'English',
};

// Render a translation. Falls back to English if Thai is missing the key,
// then to the key itself if both are missing. Supports {placeholder}
// interpolation via the optional second argument.
function translate(lang, key, vars = {}) {
  const table = lang === 'th' ? th : en;
  let str = table[key];
  if (str === undefined) str = en[key];
  if (str === undefined) return key;
  return str.replace(/\{(\w+)\}/g, (_, name) =>
    vars[name] !== undefined && vars[name] !== null ? String(vars[name]) : ''
  );
}

module.exports = { en, th, translate };
