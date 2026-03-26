import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { projectApi, formatAmount, formatDate } from '../api/api'

const STATUS_LABELS = {
  PLANNING: { label: '계획', cls: 'status-planning' },
  BIDDING: { label: '입찰', cls: 'status-bidding' },
  CONTRACTED: { label: '수주', cls: 'status-contracted' },
  IN_PROGRESS: { label: '진행중', cls: 'status-in_progress' },
  COMPLETED: { label: '완료', cls: 'status-completed' },
  SUSPENDED: { label: '일시중지', cls: 'status-suspended' },
}

const TYPE_LABELS = {
  CIVIL: '토목', BUILDING: '건축', PLANT: '플랜트',
  ELECTRICAL: '전기', MECHANICAL: '기계'
}

export default function Projects() {
  const [projects, setProjects] = useState([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState({ status: '', keyword: '' })
  const [showModal, setShowModal] = useState(false)
  const [form, setForm] = useState({})

  const load = () => {
    setLoading(true)
    const params = {}
    if (filter.status) params.status = filter.status
    if (filter.keyword) params.keyword = filter.keyword
    projectApi.getAll(params).then(r => setProjects(r.data)).finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [filter.status])

  const handleSearch = (e) => {
    e.preventDefault()
    load()
  }

  const openCreate = () => {
    setForm({
      projectCode: '',
      projectName: '',
      location: '',
      client: '',
      projectType: 'BUILDING',
      status: 'PLANNING',
      contractAmount: '',
      budget: '',
      executionBudget: '',
      startDate: '',
      plannedEndDate: '',
      siteManager: ''
    })
    setShowModal(true)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    await projectApi.create(form)
    setShowModal(false)
    load()
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <div className="page-title">PS - 프로젝트 관리</div>
          <div className="page-subtitle">공사 현장 및 프로젝트 관리 (Project System)</div>
        </div>
        <button className="btn btn-primary" onClick={openCreate}>+ 프로젝트 등록</button>
      </div>

      <div className="card">
        <form className="filter-bar" onSubmit={handleSearch}>
          <select value={filter.status} onChange={e => setFilter(f => ({ ...f, status: e.target.value }))}>
            <option value="">전체 상태</option>
            {Object.entries(STATUS_LABELS).map(([k, v]) => (
              <option key={k} value={k}>{v.label}</option>
            ))}
          </select>
          <input
            placeholder="공사명 검색..."
            value={filter.keyword}
            onChange={e => setFilter(f => ({ ...f, keyword: e.target.value }))}
          />
          <button type="submit" className="btn btn-default">검색</button>
        </form>

        <div className="table-wrap">
          {loading ? (
            <div className="loading">로딩 중...</div>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>코드</th>
                  <th>공사명</th>
                  <th>유형</th>
                  <th>발주처</th>
                  <th>상태</th>
                  <th>계약금액</th>
                  <th>공정률</th>
                  <th>착공일</th>
                  <th>준공예정</th>
                  <th>현장소장</th>
                </tr>
              </thead>
              <tbody>
                {projects.length === 0 ? (
                  <tr>
                    <td colSpan="10">
                      <div className="empty-state">
                        <div className="empty-state-icon">🏗️</div>
                        <div>프로젝트가 없습니다</div>
                      </div>
                    </td>
                  </tr>
                ) : projects.map(p => {
                  const st = STATUS_LABELS[p.status] || {}
                  return (
                    <tr key={p.id}>
                      <td>
                        <Link to={`/projects/${p.id}`} style={{ color: '#1677ff', textDecoration: 'none', fontWeight: 600 }}>
                          {p.projectCode}
                        </Link>
                      </td>
                      <td style={{ maxWidth: 220 }}>{p.projectName}</td>
                      <td>{TYPE_LABELS[p.projectType] || p.projectType}</td>
                      <td>{p.client}</td>
                      <td><span className={`badge ${st.cls}`}>{st.label}</span></td>
                      <td className="amount">{formatAmount(p.contractAmount)}</td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <div className="progress-bar">
                            <div className="progress-fill"
                              style={{
                                width: `${p.progressRate}%`,
                                background: p.progressRate >= 80 ? '#52c41a' : '#1677ff'
                              }} />
                          </div>
                          <span style={{ fontSize: 12, minWidth: 30 }}>{p.progressRate}%</span>
                        </div>
                      </td>
                      <td>{formatDate(p.startDate)}</td>
                      <td>{formatDate(p.plannedEndDate)}</td>
                      <td>{p.siteManager}</td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* 등록 모달 */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>프로젝트 등록</h3>
              <button className="modal-close" onClick={() => setShowModal(false)}>✕</button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>프로젝트 코드 *</label>
                  <input required placeholder="PRJ-2025-001" value={form.projectCode}
                    onChange={e => setForm(f => ({ ...f, projectCode: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>공사 유형</label>
                  <select value={form.projectType} onChange={e => setForm(f => ({ ...f, projectType: e.target.value }))}>
                    {Object.entries(TYPE_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                  </select>
                </div>
              </div>
              <div className="form-group">
                <label>공사명 *</label>
                <input required placeholder="OO 신축공사" value={form.projectName}
                  onChange={e => setForm(f => ({ ...f, projectName: e.target.value }))} />
              </div>
              <div className="form-group">
                <label>공사 위치</label>
                <input placeholder="서울시 강남구..." value={form.location}
                  onChange={e => setForm(f => ({ ...f, location: e.target.value }))} />
              </div>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>발주처</label>
                  <input value={form.client} onChange={e => setForm(f => ({ ...f, client: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>현장소장</label>
                  <input value={form.siteManager} onChange={e => setForm(f => ({ ...f, siteManager: e.target.value }))} />
                </div>
              </div>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>계약금액 (원)</label>
                  <input type="number" placeholder="85000000000" value={form.contractAmount}
                    onChange={e => setForm(f => ({ ...f, contractAmount: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>예산 (원)</label>
                  <input type="number" value={form.budget}
                    onChange={e => setForm(f => ({ ...f, budget: e.target.value }))} />
                </div>
              </div>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>착공일</label>
                  <input type="date" value={form.startDate}
                    onChange={e => setForm(f => ({ ...f, startDate: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>준공 예정일</label>
                  <input type="date" value={form.plannedEndDate}
                    onChange={e => setForm(f => ({ ...f, plannedEndDate: e.target.value }))} />
                </div>
              </div>
              <div className="form-group">
                <label>상태</label>
                <select value={form.status} onChange={e => setForm(f => ({ ...f, status: e.target.value }))}>
                  {Object.entries(STATUS_LABELS).map(([k, v]) => <option key={k} value={k}>{v.label}</option>)}
                </select>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-default" onClick={() => setShowModal(false)}>취소</button>
                <button type="submit" className="btn btn-primary">등록</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
