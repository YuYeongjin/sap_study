import axios from 'axios'

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

// PS - 프로젝트 관리
export const projectApi = {
  getAll: (params) => api.get('/projects', { params }),
  getById: (id) => api.get(`/projects/${id}`),
  getStats: () => api.get('/projects/stats'),
  create: (data) => api.post('/projects', data),
  update: (id, data) => api.put(`/projects/${id}`, data),
  updateProgress: (id, progressRate) => api.patch(`/projects/${id}/progress`, { progressRate }),
  delete: (id) => api.delete(`/projects/${id}`),
}

// MM - 자재 관리
export const materialApi = {
  getAll: (params) => api.get('/materials', { params }),
  getById: (id) => api.get(`/materials/${id}`),
  create: (data) => api.post('/materials', data),
  update: (id, data) => api.put(`/materials/${id}`, data),
  delete: (id) => api.delete(`/materials/${id}`),
}

// MM - 구매 발주
export const purchaseOrderApi = {
  getAll: (params) => api.get('/purchase-orders', { params }),
  getById: (id) => api.get(`/purchase-orders/${id}`),
  create: (data) => api.post('/purchase-orders', data),
  updateStatus: (id, status) => api.patch(`/purchase-orders/${id}/status`, { status }),
  delete: (id) => api.delete(`/purchase-orders/${id}`),
}

// PM - 장비 관리
export const equipmentApi = {
  getAll: (params) => api.get('/equipment', { params }),
  getById: (id) => api.get(`/equipment/${id}`),
  create: (data) => api.post('/equipment', data),
  update: (id, data) => api.put(`/equipment/${id}`, data),
  assign: (id, projectId) => api.patch(`/equipment/${id}/assign`, { projectId }),
  delete: (id) => api.delete(`/equipment/${id}`),
}

// CO - 원가 관리
export const costApi = {
  getAll: (params) => api.get('/cost-entries', { params }),
  getById: (id) => api.get(`/cost-entries/${id}`),
  getSummary: (params) => api.get('/cost-entries/summary', { params }),
  create: (data) => api.post('/cost-entries', data),
  delete: (id) => api.delete(`/cost-entries/${id}`),
}

// 금액 포맷 유틸
export function formatAmount(amount) {
  if (amount == null) return '-'
  return new Intl.NumberFormat('ko-KR', { style: 'currency', currency: 'KRW', maximumFractionDigits: 0 }).format(amount)
}

export function formatDate(dateStr) {
  if (!dateStr) return '-'
  return dateStr.substring(0, 10)
}
