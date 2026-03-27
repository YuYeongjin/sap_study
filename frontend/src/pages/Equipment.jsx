import { useState, useEffect } from 'react'
import { equipmentApi, projectApi, formatAmount, formatDate } from '../api/api'

const EQ_STATUS = {
  AVAILABLE: { label: '가용', cls: 'status-available' },
  IN_USE: { label: '투입중', cls: 'status-in_use' },
  MAINTENANCE: { label: '정비중', cls: 'status-maintenance' },
  BROKEN: { label: '고장', cls: 'status-broken' },
  DISPOSED: { label: '폐기', cls: 'status-disposed' },
}

const EQ_TYPES = {
  EXCAVATOR: '굴착기', CRANE: '크레인', DUMP_TRUCK: '덤프트럭',
  CONCRETE_PUMP: '콘크리트 펌프카', BULLDOZER: '불도저', FORKLIFT: '지게차',
  ROLLER: '롤러', COMPRESSOR: '컴프레서', GENERATOR: '발전기', OTHER: '기타'
}

export default function Equipment() {
  const [equipment, setEquipment] = useState([])
  const [projects, setProjects] = useState([])
  const [loading, setLoading] = useState(true)
  const [filterStatus, setFilterStatus] = useState('')
  const [showModal, setShowModal] = useState(false)
  const [editItem, setEditItem] = useState(null)
  const [showAssignModal, setShowAssignModal] = useState(false)
  const [assignTarget, setAssignTarget] = useState(null)
  const [assignProjectId, setAssignProjectId] = useState('')
  const [form, setForm] = useState({})

  const load = () => {
    setLoading(true)
    Promise.all([
      equipmentApi.getAll(filterStatus ? { status: filterStatus } : {}),
      projectApi.getAll({ status: 'IN_PROGRESS' }),
    ]).then(([eqRes, pRes]) => {
      setEquipment(eqRes.data)
      setProjects(pRes.data)
    }).finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [filterStatus])

  const openCreate = () => {
    setEditItem(null)
    setForm({
      equipmentCode: '', equipmentName: '', equipmentType: 'EXCAVATOR',
      model: '', manufacturer: '', registrationNumber: '',
      status: 'AVAILABLE', isRented: false, rentalCostPerDay: '',
      acquisitionDate: '', acquisitionCost: '', nextMaintenanceDate: '', totalOperatingHours: 0
    })
    setShowModal(true)
  }

  const openEdit = (eq) => {
    setEditItem(eq)
    setForm({ ...eq })
    setShowModal(true)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (editItem) {
      await equipmentApi.update(editItem.id, form)
    } else {
      await equipmentApi.create(form)
    }
    setShowModal(false)
    load()
  }

  const openAssign = (eq) => {
    setAssignTarget(eq)
    setAssignProjectId(eq.currentProject?.id || '')
    setShowAssignModal(true)
  }

  const handleAssign = async () => {
    await equipmentApi.assign(assignTarget.id, assignProjectId || null)
    setShowAssignModal(false)
    load()
  }

  const handleDelete = async (id) => {
    if (window.confirm('장비를 삭제하시겠습니까?')) {
      await equipmentApi.delete(id)
      load()
    }
  }

  // 통계
  const statusCounts = equipment.reduce((acc, eq) => {
    acc[eq.status] = (acc[eq.status] || 0) + 1
    return acc
  }, {})

  return (
    <div>
      <div className="page-header">
        <div>
          <div className="page-title">PM - 건설 장비 관리</div>
          <div className="page-subtitle">건설 장비 현황 및 현장 배치 관리 (Plant Maintenance)</div>
        </div>
        <button className="btn btn-primary" onClick={openCreate}>+ 장비 등록</button>
      </div>

      {/* 장비 통계 */}
      <div className="stat-cards" style={{ marginBottom: 16 }}>
        {Object.entries(EQ_STATUS).map(([k, v]) => (
          <div key={k} className="stat-card">
            <div className="stat-info">
              <div className="stat-value">{statusCounts[k] || 0}</div>
              <div className="stat-label">{v.label}</div>
            </div>
            <span className={`badge ${v.cls}`}>{v.label}</span>
          </div>
        ))}
      </div>

      <div className="card">
        <div className="filter-bar">
          <select value={filterStatus} onChange={e => setFilterStatus(e.target.value)}>
            <option value="">전체 상태</option>
            {Object.entries(EQ_STATUS).map(([k, v]) => <option key={k} value={k}>{v.label}</option>)}
          </select>
          <span style={{ color: '#888', fontSize: 13 }}>총 {equipment.length}대</span>
        </div>

        <div className="table-wrap">
          {loading ? <div className="loading">로딩 중...</div> : (
            <table>
              <thead>
                <tr>
                  <th>장비코드</th>
                  <th>장비명</th>
                  <th>유형</th>
                  <th>모델</th>
                  <th>상태</th>
                  <th>투입현장</th>
                  <th>소유구분</th>
                  <th>임대단가(일)</th>
                  <th>점검예정일</th>
                  <th>운영시간</th>
                  <th>작업</th>
                </tr>
              </thead>
              <tbody>
                {equipment.length === 0 ? (
                  <tr>
                    <td colSpan="11">
                      <div className="empty-state">
                        <div className="empty-state-icon">🚜</div>
                        <div>장비가 없습니다</div>
                      </div>
                    </td>
                  </tr>
                ) : equipment.map(eq => {
                  const st = EQ_STATUS[eq.status] || {}
                  const maintenanceSoon = eq.nextMaintenanceDate &&
                    new Date(eq.nextMaintenanceDate) <= new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
                  return (
                    <tr key={eq.id}>
                      <td style={{ fontWeight: 600, color: '#1677ff' }}>{eq.equipmentCode}</td>
                      <td>{eq.equipmentName}</td>
                      <td>{EQ_TYPES[eq.equipmentType] || eq.equipmentType}</td>
                      <td style={{ fontSize: 12 }}>{eq.model}</td>
                      <td><span className={`badge ${st.cls}`}>{st.label}</span></td>
                      <td style={{ fontSize: 12 }}>{eq.currentProject?.projectCode || '-'}</td>
                      <td>
                        <span className="badge" style={{
                          background: eq.isRented ? '#fff7e6' : '#f0f5ff',
                          color: eq.isRented ? '#fa8c16' : '#2f54eb'
                        }}>
                          {eq.isRented ? '임대' : '자사'}
                        </span>
                      </td>
                      <td className="amount">{eq.rentalCostPerDay ? formatAmount(eq.rentalCostPerDay) : '-'}</td>
                      <td style={{ color: maintenanceSoon ? '#ff4d4f' : 'inherit' }}>
                        {formatDate(eq.nextMaintenanceDate)}
                        {maintenanceSoon && ' ⚠️'}
                      </td>
                      <td>{eq.totalOperatingHours}h</td>
                      <td style={{ whiteSpace: 'nowrap' }}>
                        <button className="btn btn-default" style={{ fontSize: 11, padding: '3px 8px' }}
                          onClick={() => openEdit(eq)}>수정</button>
                        <button className="btn btn-default" style={{ fontSize: 11, padding: '3px 8px', marginLeft: 4 }}
                          onClick={() => openAssign(eq)}>배치</button>
                        <button className="btn btn-danger" style={{ fontSize: 11, padding: '3px 8px', marginLeft: 4 }}
                          onClick={() => handleDelete(eq.id)}>삭제</button>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* 장비 등록 모달 */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>{editItem ? '장비 수정' : '장비 등록'}</h3>
              <button className="modal-close" onClick={() => setShowModal(false)}>✕</button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>장비코드 *</label>
                  <input required value={form.equipmentCode}
                    onChange={e => setForm(f => ({ ...f, equipmentCode: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>장비유형</label>
                  <select value={form.equipmentType}
                    onChange={e => setForm(f => ({ ...f, equipmentType: e.target.value }))}>
                    {Object.entries(EQ_TYPES).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                  </select>
                </div>
              </div>
              <div className="form-group">
                <label>장비명 *</label>
                <input required value={form.equipmentName}
                  onChange={e => setForm(f => ({ ...f, equipmentName: e.target.value }))} />
              </div>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>모델명</label>
                  <input value={form.model}
                    onChange={e => setForm(f => ({ ...f, model: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>제조사</label>
                  <input value={form.manufacturer}
                    onChange={e => setForm(f => ({ ...f, manufacturer: e.target.value }))} />
                </div>
              </div>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>등록번호</label>
                  <input value={form.registrationNumber}
                    onChange={e => setForm(f => ({ ...f, registrationNumber: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>소유구분</label>
                  <select value={form.isRented}
                    onChange={e => setForm(f => ({ ...f, isRented: e.target.value === 'true' }))}>
                    <option value="false">자사</option>
                    <option value="true">임대</option>
                  </select>
                </div>
              </div>
              {form.isRented && (
                <div className="form-group">
                  <label>임대 단가 (일)</label>
                  <input type="number" value={form.rentalCostPerDay}
                    onChange={e => setForm(f => ({ ...f, rentalCostPerDay: e.target.value }))} />
                </div>
              )}
              <div className="form-grid-2">
                <div className="form-group">
                  <label>취득일자</label>
                  <input type="date" value={form.acquisitionDate}
                    onChange={e => setForm(f => ({ ...f, acquisitionDate: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>다음 점검일</label>
                  <input type="date" value={form.nextMaintenanceDate}
                    onChange={e => setForm(f => ({ ...f, nextMaintenanceDate: e.target.value }))} />
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

      {/* 현장 배치 모달 */}
      {showAssignModal && assignTarget && (
        <div className="modal-overlay" onClick={() => setShowAssignModal(false)}>
          <div className="modal" style={{ maxWidth: 400 }} onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>현장 배치 - {assignTarget.equipmentName}</h3>
              <button className="modal-close" onClick={() => setShowAssignModal(false)}>✕</button>
            </div>
            <div className="form-group">
              <label>투입 현장 선택</label>
              <select value={assignProjectId} onChange={e => setAssignProjectId(e.target.value)}>
                <option value="">배치 해제 (가용)</option>
                {projects.map(p => (
                  <option key={p.id} value={p.id}>{p.projectCode} - {p.projectName}</option>
                ))}
              </select>
            </div>
            <div className="modal-footer">
              <button className="btn btn-default" onClick={() => setShowAssignModal(false)}>취소</button>
              <button className="btn btn-primary" onClick={handleAssign}>저장</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
