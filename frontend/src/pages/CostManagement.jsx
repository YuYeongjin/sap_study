import { useState, useEffect } from 'react'
import { costApi, projectApi, formatAmount, formatDate } from '../api/api'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend
} from 'recharts'

const COST_TYPES = {
  LABOR: '노무비', MATERIAL: '재료비', EQUIPMENT_COST: '장비비',
  SUBCONTRACT: '외주비', OVERHEAD: '경비', INDIRECT: '간접비'
}

const COLORS = ['#1677ff', '#52c41a', '#fa8c16', '#ff4d4f', '#722ed1', '#13c2c2']

export default function CostManagement() {
  const [entries, setEntries] = useState([])
  const [projects, setProjects] = useState([])
  const [summary, setSummary] = useState({})
  const [filterProjectId, setFilterProjectId] = useState('')
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [form, setForm] = useState({})

const load = () => {
  setLoading(true)
  const params = filterProjectId ? { projectId: filterProjectId } : {}
  Promise.all([
    costApi.getAll(params),
    costApi.getSummary(params),
    projectApi.getAll(),
  ]).then(([eRes, sRes, pRes]) => {
    setEntries(eRes.data.value || eRes.data || [])
    
    setSummary(sRes.data.value || sRes.data || {}) 
    
    setProjects(pRes.data.value || pRes.data || [])
  }).catch(err => {
    console.error("데이터 로드 실패:", err)
  }).finally(() => setLoading(false))
}

  useEffect(() => { load() }, [filterProjectId])

  const openCreate = () => {
    setForm({
      entryNumber: `CE-2025-${String(entries.length + 1).padStart(3, '0')}`,
      projectId: filterProjectId || (projects[0]?.id || ''),
      costType: 'LABOR',
      costAccount: '',
      entryDate: new Date().toISOString().substring(0, 10),
      amount: '',
      description: '',
      createdBy: '',
    })
    setShowModal(true)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    const project = projects.find(p => p.id === Number(form.projectId))
    await costApi.create({ ...form, project })
    setShowModal(false)
    load()
  }

  const handleDelete = async (id) => {
    if (window.confirm('원가 전표를 삭제하시겠습니까?')) {
      await costApi.delete(id)
      load()
    }
  }

  const barData = Object.entries(summary).map(([name, value]) => ({
    name, 금액: Number(value)
  }))

  const pieData = Object.entries(summary)
    .filter(([, v]) => Number(v) > 0)
    .map(([name, value]) => ({ name, value: Number(value) }))

  const totalCost = Object.values(summary).reduce((s, v) => s + Number(v), 0)

  // 프로젝트별 예산 vs 실적
  const selectedProject = filterProjectId
    ? projects.find(p => p.id === Number(filterProjectId))
    : null

  return (
    <div>
      <div className="page-header">
        <div>
          <div className="page-title">CO - 원가 관리</div>
          <div className="page-subtitle">프로젝트별 원가 집계 및 예산 분석 (Controlling)</div>
        </div>
        <button className="btn btn-primary" onClick={openCreate}>+ 원가 전표 입력</button>
      </div>

      {/* 프로젝트 필터 */}
      <div className="card" style={{ marginBottom: 16 }}>
        <div className="filter-bar">
          <select value={filterProjectId} onChange={e => setFilterProjectId(e.target.value)}>
            <option value="">전체 프로젝트</option>
            {projects.map(p => (
              <option key={p.id} value={p.id}>{p.projectCode} - {p.projectName}</option>
            ))}
          </select>
          {selectedProject && (
            <div style={{ display: 'flex', gap: 16, fontSize: 13 }}>
              <span>계약금액: <strong>{formatAmount(selectedProject.contractAmount)}</strong></span>
              <span>예산: <strong>{formatAmount(selectedProject.budget)}</strong></span>
              <span>실투입: <strong style={{ color: '#ff4d4f' }}>{formatAmount(selectedProject.actualCost)}</strong></span>
              <span>예산소진율: <strong>{selectedProject.budget
                ? (Number(selectedProject.actualCost) / Number(selectedProject.budget) * 100).toFixed(1) + '%'
                : '-'}</strong></span>
            </div>
          )}
        </div>
      </div>

      {/* 원가 요약 통계 */}
      <div style={{ display: 'flex', gap: 12, marginBottom: 16 }}>
        <div className="stat-card" style={{ flex: 1 }}>
          <div className="stat-icon" style={{ background: '#f6ffed' }}>💰</div>
          <div className="stat-info">
            <div className="stat-value" style={{ fontSize: 16 }}>{formatAmount(totalCost)}</div>
            <div className="stat-label">총 투입 원가</div>
          </div>
        </div>
        <div className="stat-card" style={{ flex: 1 }}>
          <div className="stat-icon" style={{ background: '#e6f4ff' }}>📊</div>
          <div className="stat-info">
            <div className="stat-value">{entries.length}</div>
            <div className="stat-label">전표 건수</div>
          </div>
        </div>
      </div>

      {/* 차트 */}
      {barData.length > 0 && (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
          <div className="card">
            <div style={{ fontWeight: 600, marginBottom: 16 }}>원가 유형별 현황</div>
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={barData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                <YAxis tickFormatter={v => `${(v/100000000).toFixed(0)}억`} tick={{ fontSize: 11 }} />
                <Tooltip formatter={v => formatAmount(v)} />
                <Bar dataKey="금액" fill="#1677ff" radius={[4,4,0,0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
          <div className="card">
            <div style={{ fontWeight: 600, marginBottom: 16 }}>원가 구성 비율</div>
            <ResponsiveContainer width="100%" height={220}>
              <PieChart>
                <Pie data={pieData} dataKey="value" nameKey="name" cx="50%" cy="50%"
                  outerRadius={80} label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}>
                  {pieData.map((_, i) => (
                    <Cell key={i} fill={COLORS[i % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip formatter={v => formatAmount(v)} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}

      {/* 원가 전표 목록 */}
      <div className="card">
        <div className="table-wrap">
          {loading ? <div className="loading">로딩 중...</div> : (
            <table>
              <thead>
                <tr>
                  <th>전표번호</th>
                  <th>프로젝트</th>
                  <th>원가유형</th>
                  <th>계정항목</th>
                  <th>발생일</th>
                  <th>금액</th>
                  <th>적요</th>
                  <th>증빙번호</th>
                  <th>입력자</th>
                  <th>작업</th>
                </tr>
              </thead>
              <tbody>
                {entries.length === 0 ? (
                  <tr>
                    <td colSpan="10">
                      <div className="empty-state">
                        <div className="empty-state-icon">💰</div>
                        <div>원가 전표가 없습니다</div>
                      </div>
                    </td>
                  </tr>
                ) : entries.map(c => (
                  <tr key={c.id}>
                    <td style={{ fontWeight: 600 }}>{c.entryNumber}</td>
                    <td style={{ fontSize: 12 }}>{c.project?.projectCode}</td>
                    <td>
                      <span className="badge" style={{ background: '#e6f4ff', color: '#1677ff' }}>
                        {COST_TYPES[c.costType] || c.costType}
                      </span>
                    </td>
                    <td>{c.costAccount}</td>
                    <td>{formatDate(c.entryDate)}</td>
                    <td className="amount" style={{ fontWeight: 600 }}>{formatAmount(c.amount)}</td>
                    <td style={{ maxWidth: 180, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontSize: 12 }}>
                      {c.description}
                    </td>
                    <td style={{ fontSize: 12, color: '#888' }}>{c.documentNumber || '-'}</td>
                    <td style={{ fontSize: 12 }}>{c.createdBy}</td>
                    <td>
                      <button className="btn btn-danger" style={{ fontSize: 11, padding: '3px 8px' }}
                        onClick={() => handleDelete(c.id)}>삭제</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* 원가 전표 입력 모달 */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>원가 전표 입력</h3>
              <button className="modal-close" onClick={() => setShowModal(false)}>✕</button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>전표번호 *</label>
                  <input required value={form.entryNumber}
                    onChange={e => setForm(f => ({ ...f, entryNumber: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>프로젝트 *</label>
                  <select required value={form.projectId}
                    onChange={e => setForm(f => ({ ...f, projectId: e.target.value }))}>
                    <option value="">선택</option>
                    {projects.map(p => (
                      <option key={p.id} value={p.id}>{p.projectCode} - {p.projectName.substring(0, 15)}</option>
                    ))}
                  </select>
                </div>
              </div>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>원가유형</label>
                  <select value={form.costType}
                    onChange={e => setForm(f => ({ ...f, costType: e.target.value }))}>
                    {Object.entries(COST_TYPES).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                  </select>
                </div>
                <div className="form-group">
                  <label>계정항목</label>
                  <input value={form.costAccount}
                    onChange={e => setForm(f => ({ ...f, costAccount: e.target.value }))} />
                </div>
              </div>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>발생일</label>
                  <input type="date" value={form.entryDate}
                    onChange={e => setForm(f => ({ ...f, entryDate: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>금액 (원) *</label>
                  <input type="number" required value={form.amount}
                    onChange={e => setForm(f => ({ ...f, amount: e.target.value }))} />
                </div>
              </div>
              <div className="form-group">
                <label>적요</label>
                <textarea rows="2" value={form.description}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))} />
              </div>
              <div className="form-grid-2">
                <div className="form-group">
                  <label>증빙 문서번호</label>
                  <input value={form.documentNumber || ''}
                    onChange={e => setForm(f => ({ ...f, documentNumber: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>입력자</label>
                  <input value={form.createdBy}
                    onChange={e => setForm(f => ({ ...f, createdBy: e.target.value }))} />
                </div>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-default" onClick={() => setShowModal(false)}>취소</button>
                <button type="submit" className="btn btn-primary">입력</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
