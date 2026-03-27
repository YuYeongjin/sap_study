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
