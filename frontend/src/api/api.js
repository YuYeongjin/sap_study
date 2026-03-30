import axios from 'axios'

// ABAP REST API 클라이언트
// Vite proxy: /api/* → http://localhost:4004/sap/bc/zconstruction/*
const api = axios.create({
  baseURL: '/api',
  headers: { 'Content-Type': 'application/json' }
})

// 에러 핸들링
api.interceptors.response.use(
  res => res,
  err => {
    console.error('API Error:', err.response?.data || err.message)
    return Promise.reject(err)
  }
)

// ============================================================
// PS - 프로젝트 관리
// ZCL_REST_PROJECT → /sap/bc/zconstruction/projects
// ============================================================
export const projectApi = {
  // Dashboard.jsx: getAll({ status: 'IN_PROGRESS' })
  // Projects.jsx:  getAll(params) - params에 status, keyword 포함 가능
  getAll: (params) => api.get('/projects', { params }),

  getById: (id) => api.get('/projects', { params: { id } }),

  getByStatus: (status) => api.get('/projects', { params: { status } }),

  search: (keyword) => api.get('/projects', { params: { keyword } }),

  // Dashboard.jsx: getStats()
  getStats: () => api.get('/projects', { params: { stats: 1 } }),

  create: (data) => api.post('/projects', data),

  update: (id, data) => api.put('/projects', data, { params: { id } }),

  // ProjectDetail.jsx: updateProgress(id, newProgress)
  // ABAP: PUT /projects?id=:id with body { progress_rate }
  updateProgress: (id, progressRate) =>
    api.put('/projects', { progress_rate: progressRate }, { params: { id } }),

  delete: (id) => api.delete('/projects', { params: { id } }),
}

// ============================================================
// MM - 자재 관리
// ZCL_REST_MATERIAL → /sap/bc/zconstruction/materials
// ============================================================
export const materialApi = {
  // Materials.jsx: getAll(params) - params에 category, lowStock, keyword 포함
  // lowStock(camelCase) → lowstock(ABAP query param) 변환
  getAll: (params) => {
    const abapParams = { ...params }
    if (abapParams.lowStock) {
      abapParams.lowstock = 1
      delete abapParams.lowStock
    }
    return api.get('/materials', { params: abapParams })
  },

  getById: (id) => api.get('/materials', { params: { id } }),

  getByCategory: (category) => api.get('/materials', { params: { category } }),

  getLowStock: () => api.get('/materials', { params: { lowstock: 1 } }),

  search: (keyword) => api.get('/materials', { params: { keyword } }),

  create: (data) => api.post('/materials', data),

  update: (id, data) => api.put('/materials', data, { params: { id } }),

  delete: (id) => api.delete('/materials', { params: { id } }),
}

// ============================================================
// MM - 구매 발주
// ZCL_REST_PO → /sap/bc/zconstruction/purchase-orders
// ============================================================
export const purchaseOrderApi = {
  // ProjectDetail.jsx: getAll({ projectId: id })
  // PurchaseOrders.jsx: getAll(params) - params에 status 포함
  // projectId(camelCase) → project_id(ABAP query param) 변환
  getAll: (params) => {
    const abapParams = { ...params }
    if (abapParams.projectId) {
      abapParams.project_id = abapParams.projectId
      delete abapParams.projectId
    }
    return api.get('/purchase-orders', { params: abapParams })
  },

  getById: (id) => api.get('/purchase-orders', { params: { id } }),

  // PurchaseOrders.jsx: updateStatus(id, newStatus)
  // ABAP: PUT /purchase-orders?id=:id&status=:status
  updateStatus: (id, status) =>
    api.put('/purchase-orders', null, { params: { id, status } }),

  create: (data) => api.post('/purchase-orders', data),

  update: (id, data) => api.put('/purchase-orders', data, { params: { id } }),

  delete: (id) => api.delete('/purchase-orders', { params: { id } }),
}

// ============================================================
// PM - 장비 관리
// ZCL_REST_EQUIPMENT → /sap/bc/zconstruction/equipment
// ============================================================
export const equipmentApi = {
  // ProjectDetail.jsx: getAll({ projectId: id })
  // Equipment.jsx:     getAll(params) - params에 status 포함
  // projectId(camelCase) → project_id(ABAP query param) 변환
  getAll: (params) => {
    const abapParams = { ...params }
    if (abapParams.projectId) {
      abapParams.project_id = abapParams.projectId
      delete abapParams.projectId
    }
    return api.get('/equipment', { params: abapParams })
  },

  getById: (id) => api.get('/equipment', { params: { id } }),

  create: (data) => api.post('/equipment', data),

  update: (id, data) => api.put('/equipment', data, { params: { id } }),

  // Equipment.jsx: assign(id, projectId)
  // ABAP: PUT /equipment?id=:id&assign=:projectId
  assign: (id, projectId) =>
    api.put('/equipment', null, { params: { id, assign: projectId } }),

  delete: (id) => api.delete('/equipment', { params: { id } }),
}

// ============================================================
// CO - 원가 관리
// ZCL_REST_COST → /sap/bc/zconstruction/cost-entries
// ============================================================
export const costApi = {
  // ProjectDetail.jsx: getAll({ projectId: id })
  // CostManagement.jsx: getAll(params) - params에 projectId 포함
  // projectId(camelCase) → project_id(ABAP query param) 변환
  getAll: (params) => {
    const abapParams = { ...params }
    if (abapParams.projectId) {
      abapParams.project_id = abapParams.projectId
      delete abapParams.projectId
    }
    return api.get('/cost-entries', { params: abapParams })
  },

  getById: (id) => api.get('/cost-entries', { params: { id } }),

  // Dashboard.jsx:      getSummary()           → 전체 요약
  // ProjectDetail.jsx:  getSummary({ projectId }) → 프로젝트별 요약
  // CostManagement.jsx: getSummary(params)      → projectId 유무에 따라 분기
  getSummary: (params) => {
    if (params?.projectId) {
      return api.get('/cost-entries', {
        params: { project_id: params.projectId, summary: 1 }
      })
    }
    return api.get('/cost-entries', { params: { all_summary: 1 } })
  },

  create: (data) => api.post('/cost-entries', data),

  update: (id, data) => api.put('/cost-entries', data, { params: { id } }),

  delete: (id) => api.delete('/cost-entries', { params: { id } }),
}

// ============================================================
// FI - 재무회계 공통 axios 인스턴스
// /api/fi/* → /sap/bc/zfi/*
// ============================================================
const fiApi = axios.create({
  baseURL: '/api/fi',
  headers: { 'Content-Type': 'application/json' }
})
fiApi.interceptors.response.use(res => res, err => {
  console.error('FI API Error:', err.response?.data || err.message)
  return Promise.reject(err)
})

// CO - 관리회계 공통 axios 인스턴스
// /api/co/* → /sap/bc/zco/*
const coApi = axios.create({
  baseURL: '/api/co',
  headers: { 'Content-Type': 'application/json' }
})
coApi.interceptors.response.use(res => res, err => {
  console.error('CO API Error:', err.response?.data || err.message)
  return Promise.reject(err)
})

// ============================================================
// FI - AR (매출채권)
// ZCL_REST_FI_AR → /sap/bc/zfi/ar/
// ============================================================
export const arApi = {
  // 고객 마스터
  getCustomers: (params) => fiApi.get('/ar/customers', { params }),
  createCustomer: (data) => fiApi.post('/ar/customers', data),
  updateCustomer: (id, data) => fiApi.put('/ar/customers', data, { params: { id } }),

  // 청구서
  getInvoices: (params) => fiApi.get('/ar/invoices', { params }),
  createInvoice: (data) => fiApi.post('/ar/invoices', data),
  updateInvoice: (id, data) => fiApi.put('/ar/invoices', data, { params: { id } }),
  deleteInvoice: (id) => fiApi.delete('/ar/invoices', { params: { id } }),

  // 수금 처리
  processReceipt: (data) => fiApi.post('/ar/receipt', data),

  // 대손 처리
  writeBadDebt: (data) => fiApi.post('/ar/baddebt', data),

  // 연령분석
  getAging: (bukrs) => fiApi.get('/ar/aging', { params: { bukrs } }),

  // 프로젝트별 수익 현황
  getRevenue: (params) => fiApi.get('/ar/revenue', { params }),
}

// ============================================================
// FI - AP (매입채무)
// ZCL_REST_FI_AP → /sap/bc/zfi/ap/
// ============================================================
export const apApi = {
  // 벤더 마스터
  getVendors: (params) => fiApi.get('/ap/vendors', { params }),
  createVendor: (data) => fiApi.post('/ap/vendors', data),
  updateVendor: (id, data) => fiApi.put('/ap/vendors', data, { params: { id } }),
  blockVendor: (id) => fiApi.delete('/ap/vendors', { params: { id } }),

  // 매입전표
  getInvoices: (params) => fiApi.get('/ap/invoices', { params }),
  createInvoice: (data) => fiApi.post('/ap/invoices', data),
  updateInvoice: (id, data) => fiApi.put('/ap/invoices', data, { params: { id } }),
  deleteInvoice: (id) => fiApi.delete('/ap/invoices', { params: { id } }),
  getOverdue: () => fiApi.get('/ap/invoices', { params: { overdue: 'X' } }),

  // 지급 처리
  processPayment: (data) => fiApi.post('/ap/payment', data),

  // 연령분석
  getAging: (bukrs) => fiApi.get('/ap/aging', { params: { bukrs } }),
}

// ============================================================
// FI - GL (총계정원장)
// ZCL_FI_GL_SERVICE (REST 핸들러 추가 예정: /sap/bc/zfi/gl/)
// ============================================================
export const glApi = {
  getAccounts: (bukrs) => fiApi.get('/gl/accounts', { params: { bukrs } }),
  createAccount: (data) => fiApi.post('/gl/accounts', data),
  postJournal: (data) => fiApi.post('/gl/journals', data),
  getJournals: (params) => fiApi.get('/gl/journals', { params }),
  reverseJournal: (data) => fiApi.post('/gl/journals/reverse', data),
  getTrialBalance: (params) => fiApi.get('/gl/trial-balance', { params }),
}

// ============================================================
// FI - Asset Accounting (고정자산)
// ZCL_FI_ASSET_SERVICE (REST 핸들러 추가 예정: /sap/bc/zfi/asset/)
// ============================================================
export const assetApi = {
  getAssets: (bukrs) => fiApi.get('/asset/assets', { params: { bukrs } }),
  acquireAsset: (data) => fiApi.post('/asset/assets', data),
  retireAsset: (data) => fiApi.post('/asset/assets/retire', data),
  getDeprHistory: (params) => fiApi.get('/asset/depreciation', { params }),
  simulateDepr: (params) => fiApi.get('/asset/depreciation/simulate', { params }),
  runDeprRun: (data) => fiApi.post('/asset/depreciation/run', data),
}

// ============================================================
// CO - 내부오더
// ZCL_REST_CO_ORDER → /sap/bc/zco/orders, /sap/bc/zco/budgets
// ============================================================
export const coOrderApi = {
  getAll: (params) => coApi.get('/orders', { params }),
  create: (data) => coApi.post('/orders', data),
  update: (id, data) => coApi.put('/orders', data, { params: { id } }),
  release: (data) => coApi.post('/orders/release', data),
  settle: (data) => coApi.post('/orders/settle', data),
  getBudget: (id) => coApi.get('/orders', { params: { budget: id } }),
  getCostDetail: (id) => coApi.get('/orders', { params: { cost: id } }),
  getOverBudget: () => coApi.get('/orders', { params: { overbudget: 'X' } }),
  saveBudget: (data) => coApi.post('/budgets', data),
}

// ============================================================
// CO - 코스트센터
// ZCL_CO_COSTCENTER_SERVICE (REST 핸들러 추가 예정: /sap/bc/zco/costcenters/)
// ============================================================
export const coCostCenterApi = {
  getAll: (kokrs) => coApi.get('/costcenters', { params: { kokrs } }),
  create: (data) => coApi.post('/costcenters', data),
  update: (id, data) => coApi.put('/costcenters', data, { params: { id } }),
  savePlan: (data) => coApi.post('/costcenters/plan', data),
  getVariance: (params) => coApi.get('/costcenters/variance', { params }),
  getMonthlyTrend: (params) => coApi.get('/costcenters/trend', { params }),
}

// ============================================================
// CO - 손익센터
// ZCL_CO_PROFITCENTER_SERVICE (REST 핸들러 추가 예정: /sap/bc/zco/profitcenters/)
// ============================================================
export const coProfitCenterApi = {
  getAll: (kokrs) => coApi.get('/profitcenters', { params: { kokrs } }),
  create: (data) => coApi.post('/profitcenters', data),
  update: (id, data) => coApi.put('/profitcenters', data, { params: { id } }),
  getPL: (params) => coApi.get('/profitcenters/pl', { params }),
  getMonthlyTrend: (params) => coApi.get('/profitcenters/trend', { params }),
}

// ============================================================
// AI 챗봇 - Spring Boot 전용 (ABAP 미구현)
// ChatBot.jsx에서 직접 axios로 호출 중이므로 proxy 설정 필요
// vite.config.js에 '/api/ai' → Spring Boot 8080 프록시를 별도 추가해야 함
// ============================================================

// ============================================================
// 유틸
// ============================================================
export function formatAmount(amount) {
  if (amount == null) return '-'
  return new Intl.NumberFormat('ko-KR', {
    style: 'currency',
    currency: 'KRW',
    maximumFractionDigits: 0
  }).format(amount)
}

export function formatDate(dateStr) {
  if (!dateStr) return '-'
  // ABAP DATS 형식 'YYYYMMDD' → 'YYYY-MM-DD'
  if (dateStr.length === 8 && !dateStr.includes('-')) {
    return `${dateStr.slice(0, 4)}-${dateStr.slice(4, 6)}-${dateStr.slice(6, 8)}`
  }
  return dateStr.substring(0, 10)
}
