import { useState, useEffect } from 'react'
import { materialApi, formatAmount } from '../api/api'

const CATEGORY_LABELS = {
  STEEL: '철강', CONCRETE: '콘크리트', WOOD: '목재',
  ELECTRICAL: '전기자재', PIPING: '배관', FINISHING: '마감재',
  EQUIPMENT: '장비', SAFETY: '안전용품', CHEMICAL: '화학', OTHER: '기타'
}

export default function Materials() {
  const [materials, setMaterials] = useState([])
  const [loading, setLoading] = useState(true)
  const [filterCategory, setFilterCategory] = useState('')
  const [keyword, setKeyword] = useState('')
  const [showLowStock, setShowLowStock] = useState(false)
  const [showModal, setShowModal] = useState(false)
  const [editItem, setEditItem] = useState(null)
  const [form, setForm] = useState({})

  const load = () => {
    setLoading(true)
    const params = {}
    if (showLowStock) params.lowStock = true
    else if (filterCategory) params.category = filterCategory
    materialApi.getAll(params).then(r => setMaterials(r.data)).finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [filterCategory, showLowStock])

  const handleSearch = (e) => {
    e.preventDefault()
    materialApi.getAll({ keyword }).then(r => setMaterials(r.data))
  }

  const openCreate = () => {
    setEditItem(null)
    setForm({
      materialCode: '', materialName: '', category: 'STEEL',
      specification: '', unit: 'EA', standardPrice: '',
      stockQuantity: '0', safetyStock: '', primaryVendor: '', leadTimeDays: ''
    })
    setShowModal(true)
  }

  const openEdit = (mat) => {
    setEditItem(mat)
    setForm({ ...mat })
    setShowModal(true)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (editItem) {
      await materialApi.update(editItem.id, form)
    } else {
      await materialApi.create(form)
    }
    setShowModal(false)
    load()
  }

  const handleDelete = async (id) => {
    if (window.confirm('자재를 삭제하시겠습니까?')) {
      await materialApi.delete(id)
      load()
    }
  }

  const getStockStatus = (mat) => {
    if (!mat.safetyStock) return null
    const ratio = Number(mat.stockQuantity) / Number(mat.safetyStock)
    if (ratio <= 0) return { label: '재고없음', color: '#ff4d4f' }
    if (ratio <= 1) return { label: '부족', color: '#fa8c16' }
    return { label: '정상', color: '#52c41a' }
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <div className="page-title">MM - 자재 관리</div>
          <div className="page-subtitle">건설 자재 마스터 및 재고 현황 (Material Management)</div>
        </div>
        <button className="btn btn-primary" onClick={openCreate}>+ 자재 등록</button>
      </div>

      <div className="card">
        <div className="filter-bar">
          <form onSubmit={handleSearch} style={{ display: 'flex', gap: 8 }}>
            <input placeholder="자재명 검색..." value={keyword}
              onChange={e => setKeyword(e.target.value)} />
            <button type="submit" className="btn btn-default">검색</button>
          </form>
          <select value={filterCategory} onChange={e => { setFilterCategory(e.target.value); setShowLowStock(false) }}>
            <option value="">전체 분류</option>
            {Object.entries(CATEGORY_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
          </select>
          <button
            className={`btn ${showLowStock ? 'btn-warning' : 'btn-default'}`}
            onClick={() => { setShowLowStock(!showLowStock); setFilterCategory('') }}
          >
            ⚠️ 부족 재고만
          </button>
          <span style={{ color: '#888', fontSize: 13 }}>총 {materials.length}건</span>
        </div>

        <div className="table-wrap">
          {loading ? <div className="loading">로딩 중...</div> : (
            <table>
              <thead>
                <tr>
                  <th>자재코드</th>
                  <th>자재명</th>
                  <th>분류</th>
                  <th>규격</th>
                  <th>단위</th>
                  <th>표준단가</th>
                  <th>재고수량</th>
                  <th>안전재고</th>
                  <th>재고상태</th>
                  <th>주요공급업체</th>
                  <th>작업</th>
                </tr>
              </thead>
              <tbody>
                {materials.length === 0 ? (
                  <tr>
                    <td colSpan="11">
                      <div className="empty-state">
                        <div className="empty-state-icon">🧱</div>
                        <div>자재가 없습니다</div>
                      </div>
                    </td>
                  </tr>
                ) : materials.map(m => {
                  const stockStatus = getStockStatus(m)
                  return (
                    <tr key={m.id}>
                      <td style={{ fontWeight: 600, color: '#1677ff' }}>{m.materialCode}</td>
                      <td>{m.materialName}</td>
                      <td>{CATEGORY_LABELS[m.category] || m.category}</td>
                      <td style={{ fontSize: 12, color: '#666', maxWidth: 150, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {m.specification}
                      </td>
                      <td>{m.unit}</td>
                      <td className="amount">{formatAmount(m.standardPrice)}</td>
                      <td style={{ fontWeight: 600 }}>{Number(m.stockQuantity).toLocaleString()} {m.unit}</td>
                      <td style={{ color: '#888' }}>{m.safetyStock ? `${Number(m.safetyStock).toLocaleString()} ${m.unit}` : '-'}</td>
                      <td>
                        {stockStatus ? (
                          <span className="badge" style={{ background: stockStatus.color + '20', color: stockStatus.color }}>
                            {stockStatus.label}
                          </span>
                        ) : '-'}
                      </td>
                      <td>{m.primaryVendor}</td>
                      <td style={{ whiteSpace: 'nowrap' }}>
                        <button className="btn btn-default" style={{ fontSize: 11, padding: '3px 8px' }}
                          onClick={() => openEdit(m)}>수정</button>
                        <button className="btn btn-danger" style={{ fontSize: 11, padding: '3px 8px', marginLeft: 4 }}
                          onClick={() => handleDelete(m.id)}>삭제</button>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* 자재 등록/수정 모달 */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>{editItem ? '자재 수정' : '자재 등록'}</h3>
              <button className="modal-close" onClick={() => setShowModal(false)}>✕</button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>자재코드 *</label>
                  <input required value={form.materialCode}
                    onChange={e => setForm(f => ({ ...f, materialCode: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>분류</label>
                  <select value={form.category} onChange={e => setForm(f => ({ ...f, category: e.target.value }))}>
                    {Object.entries(CATEGORY_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                  </select>
                </div>
              </div>
              <div className="form-group">
                <label>자재명 *</label>
                <input required value={form.materialName}
                  onChange={e => setForm(f => ({ ...f, materialName: e.target.value }))} />
              </div>
              <div className="form-group">
                <label>규격/사양</label>
                <input value={form.specification}
                  onChange={e => setForm(f => ({ ...f, specification: e.target.value }))} />
              </div>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>단위</label>
                  <select value={form.unit} onChange={e => setForm(f => ({ ...f, unit: e.target.value }))}>
                    {['EA', 'KG', 'TON', 'M', 'M2', 'M3', 'BOX', 'SET', 'L'].map(u => (
                      <option key={u} value={u}>{u}</option>
                    ))}
                  </select>
                </div>
                <div className="form-group">
                  <label>표준단가 (원)</label>
                  <input type="number" value={form.standardPrice}
                    onChange={e => setForm(f => ({ ...f, standardPrice: e.target.value }))} />
                </div>
              </div>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>현재 재고</label>
                  <input type="number" step="0.001" value={form.stockQuantity}
                    onChange={e => setForm(f => ({ ...f, stockQuantity: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>안전 재고</label>
                  <input type="number" step="0.001" value={form.safetyStock}
                    onChange={e => setForm(f => ({ ...f, safetyStock: e.target.value }))} />
                </div>
              </div>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>주요 공급업체</label>
                  <input value={form.primaryVendor}
                    onChange={e => setForm(f => ({ ...f, primaryVendor: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>리드타임 (일)</label>
                  <input type="number" value={form.leadTimeDays}
                    onChange={e => setForm(f => ({ ...f, leadTimeDays: e.target.value }))} />
                </div>
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
