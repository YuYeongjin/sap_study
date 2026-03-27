import { useState, useEffect } from 'react'
import { purchaseOrderApi, projectApi, formatAmount, formatDate } from '../api/api'

const PO_STATUS = {
  DRAFT: { label: '초안', cls: 'status-draft' },
  PENDING: { label: '승인대기', cls: 'status-pending' },
  APPROVED: { label: '승인완료', cls: 'status-approved' },
  ORDERED: { label: '발주완료', cls: 'status-ordered' },
  PARTIAL_RECEIVED: { label: '부분입고', cls: 'status-partial_received' },
  RECEIVED: { label: '입고완료', cls: 'status-received' },
  CANCELLED: { label: '취소', cls: 'status-cancelled' },
}

const NEXT_STATUS = {
  DRAFT: 'PENDING',
  PENDING: 'APPROVED',
  APPROVED: 'ORDERED',
  ORDERED: 'RECEIVED',
}

export default function PurchaseOrders() {
  const [orders, setOrders] = useState([])
  const [projects, setProjects] = useState([])
  const [loading, setLoading] = useState(true)
  const [filterStatus, setFilterStatus] = useState('')
  const [showModal, setShowModal] = useState(false)
  const [editItem, setEditItem] = useState(null)
  const [form, setForm] = useState({})

  const load = () => {
    setLoading(true)
    const params = filterStatus ? { status: filterStatus } : {}
    Promise.all([
      purchaseOrderApi.getAll(params),
      projectApi.getAll(),
    ]).then(([poRes, pRes]) => {
      setOrders(poRes.data)
      setProjects(pRes.data)
    }).finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [filterStatus])

  const handleStatusUpdate = async (id, newStatus) => {
    await purchaseOrderApi.updateStatus(id, newStatus)
    load()
  }

  const openCreate = () => {
    setEditItem(null)
    setForm({
      poNumber: `PO-2025-${String(orders.length + 1).padStart(4, '0')}`,
      projectId: projects[0]?.id || '',
      vendorName: '',
      vendorCode: '',
      orderDate: new Date().toISOString().substring(0, 10),
      deliveryDate: '',
      deliveryAddress: '',
      purchaser: '',
      remarks: '',
    })
    setShowModal(true)
  }

  const openEdit = (po) => {
    setEditItem(po)
    setForm({ ...po, projectId: po.project?.id || po.projectId || '' })
    setShowModal(true)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    const project = projects.find(p => p.id === Number(form.projectId))
    if (editItem) {
      await purchaseOrderApi.update(editItem.id, { ...form, project })
    } else {
      await purchaseOrderApi.create({ ...form, project })
    }
    setShowModal(false)
    load()
  }

  const handleDelete = async (id) => {
    if (window.confirm('발주서를 삭제하시겠습니까?')) {
      await purchaseOrderApi.delete(id)
      load()
    }
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <div className="page-title">MM - 구매 발주 관리</div>
          <div className="page-subtitle">건설 자재 구매 발주서 관리 (Purchase Order)</div>
        </div>
        <button className="btn btn-primary" onClick={openCreate}>+ 발주 등록</button>
      </div>

      <div className="card">
        <div className="filter-bar">
          <select value={filterStatus} onChange={e => setFilterStatus(e.target.value)}>
            <option value="">전체 상태</option>
            {Object.entries(PO_STATUS).map(([k, v]) => (
              <option key={k} value={k}>{v.label}</option>
            ))}
          </select>
          <span style={{ color: '#888', fontSize: 13 }}>총 {orders.length}건</span>
        </div>

        <div className="table-wrap">
          {loading ? <div className="loading">로딩 중...</div> : (
            <table>
              <thead>
                <tr>
                  <th>발주번호</th>
                  <th>프로젝트</th>
                  <th>공급업체</th>
                  <th>상태</th>
                  <th>발주일</th>
                  <th>납품요청일</th>
                  <th>총금액</th>
                  <th>담당자</th>
                  <th>작업</th>
                </tr>
              </thead>
              <tbody>
                {orders.length === 0 ? (
                  <tr>
                    <td colSpan="9">
                      <div className="empty-state">
                        <div className="empty-state-icon">📋</div>
                        <div>발주 내역이 없습니다</div>
                      </div>
                    </td>
                  </tr>
                ) : orders.map(po => {
                  const st = PO_STATUS[po.status] || {}
                  const nextStatus = NEXT_STATUS[po.status]
                  return (
                    <tr key={po.id}>
                      <td style={{ fontWeight: 600, color: '#1677ff' }}>{po.poNumber}</td>
                      <td style={{ fontSize: 12 }}>{po.project?.projectCode}</td>
                      <td>{po.vendorName}</td>
                      <td><span className={`badge ${st.cls}`}>{st.label}</span></td>
                      <td>{formatDate(po.orderDate)}</td>
                      <td>{formatDate(po.deliveryDate)}</td>
                      <td className="amount">{formatAmount(po.totalAmount)}</td>
                      <td>{po.purchaser}</td>
                      <td style={{ whiteSpace: 'nowrap' }}>
                        <button className="btn btn-default"
                          style={{ fontSize: 11, padding: '4px 8px' }}
                          onClick={() => openEdit(po)}>수정</button>
                        {nextStatus && (
                          <button
                            className="btn btn-primary"
                            style={{ fontSize: 11, padding: '4px 8px', marginLeft: 4 }}
                            onClick={() => handleStatusUpdate(po.id, nextStatus)}
                          >
                            {PO_STATUS[nextStatus]?.label} 처리
                          </button>
                        )}
                        {po.status !== 'CANCELLED' && po.status !== 'RECEIVED' && (
                          <button
                            className="btn btn-danger"
                            style={{ fontSize: 11, padding: '4px 8px', marginLeft: 4 }}
                            onClick={() => handleStatusUpdate(po.id, 'CANCELLED')}
                          >
                            취소
                          </button>
                        )}
                        <button
                          className="btn btn-danger"
                          style={{ fontSize: 11, padding: '4px 8px', marginLeft: 4 }}
                          onClick={() => handleDelete(po.id)}
                        >
                          삭제
                        </button>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* 발주 등록 모달 */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>{editItem ? '구매 발주 수정' : '구매 발주 등록'}</h3>
              <button className="modal-close" onClick={() => setShowModal(false)}>✕</button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>발주번호 *</label>
                  <input required value={form.poNumber}
                    onChange={e => setForm(f => ({ ...f, poNumber: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>프로젝트</label>
                  <select value={form.projectId}
                    onChange={e => setForm(f => ({ ...f, projectId: e.target.value }))}>
                    <option value="">선택</option>
                    {projects.map(p => (
                      <option key={p.id} value={p.id}>{p.projectCode} - {p.projectName}</option>
                    ))}
                  </select>
                </div>
              </div>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>공급업체명 *</label>
                  <input required value={form.vendorName}
                    onChange={e => setForm(f => ({ ...f, vendorName: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>공급업체 코드</label>
                  <input value={form.vendorCode}
                    onChange={e => setForm(f => ({ ...f, vendorCode: e.target.value }))} />
                </div>
              </div>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>발주일</label>
                  <input type="date" value={form.orderDate}
                    onChange={e => setForm(f => ({ ...f, orderDate: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>납품 요청일</label>
                  <input type="date" value={form.deliveryDate}
                    onChange={e => setForm(f => ({ ...f, deliveryDate: e.target.value }))} />
                </div>
              </div>
              <div className="form-group">
                <label>납품 주소</label>
                <input value={form.deliveryAddress}
                  onChange={e => setForm(f => ({ ...f, deliveryAddress: e.target.value }))} />
              </div>
              <div className="form-group">
                <label>구매 담당자</label>
                <input value={form.purchaser}
                  onChange={e => setForm(f => ({ ...f, purchaser: e.target.value }))} />
              </div>
              <div className="form-group">
                <label>비고</label>
                <textarea rows="2" value={form.remarks}
                  onChange={e => setForm(f => ({ ...f, remarks: e.target.value }))} />
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-default" onClick={() => setShowModal(false)}>취소</button>
                <button type="submit" className="btn btn-primary">{editItem ? '수정' : '등록'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
