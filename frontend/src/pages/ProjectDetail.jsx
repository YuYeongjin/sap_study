import { useState, useEffect } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { projectApi, purchaseOrderApi, costApi, equipmentApi, formatAmount, formatDate } from '../api/api'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import './ProjectDetail.css'

const STATUS_LABELS = {
  PLANNING: { label: '계획', cls: 'status-planning' },
  BIDDING: { label: '입찰', cls: 'status-bidding' },
  CONTRACTED: { label: '수주', cls: 'status-contracted' },
  IN_PROGRESS: { label: '진행중', cls: 'status-in_progress' },
  COMPLETED: { label: '완료', cls: 'status-completed' },
  SUSPENDED: { label: '일시중지', cls: 'status-suspended' },
}

const PO_STATUS = {
  DRAFT: { label: '초안', cls: 'status-draft' },
  PENDING: { label: '승인대기', cls: 'status-pending' },
  APPROVED: { label: '승인완료', cls: 'status-approved' },
  ORDERED: { label: '발주완료', cls: 'status-ordered' },
  PARTIAL_RECEIVED: { label: '부분입고', cls: 'status-partial_received' },
  RECEIVED: { label: '입고완료', cls: 'status-received' },
  CANCELLED: { label: '취소', cls: 'status-cancelled' },
}

export default function ProjectDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [project, setProject] = useState(null)
  const [purchaseOrders, setPurchaseOrders] = useState([])
  const [costEntries, setCostEntries] = useState([])
  const [costSummary, setCostSummary] = useState({})
  const [equipment, setEquipment] = useState([])
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState('info')
  const [editProgress, setEditProgress] = useState(false)
  const [newProgress, setNewProgress] = useState(0)

  const load = () => {
    Promise.all([
      projectApi.getById(id),
      purchaseOrderApi.getAll({ projectId: id }),
      costApi.getAll({ projectId: id }),
      costApi.getSummary({ projectId: id }),
      equipmentApi.getAll({ projectId: id }),
    ]).then(([pRes, poRes, ceRes, csRes, eqRes]) => {
      setProject(pRes.data)
      setNewProgress(pRes.data.progressRate)
      setPurchaseOrders(poRes.data)
      setCostEntries(ceRes.data)
      setCostSummary(csRes.data)
      setEquipment(eqRes.data)
    }).finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [id])

  const handleProgressUpdate = async () => {
    await projectApi.updateProgress(id, newProgress)
    setEditProgress(false)
    load()
  }

  const handleDelete = async () => {
    if (window.confirm('프로젝트를 삭제하시겠습니까?')) {
      await projectApi.delete(id)
      navigate('/projects')
    }
  }

  if (loading) return <div className="loading">로딩 중...</div>
  if (!project) return <div className="empty-state">프로젝트를 찾을 수 없습니다.</div>

  const st = STATUS_LABELS[project.status] || {}
  const budgetUtilization = project.budget
    ? (Number(project.actualCost) / Number(project.budget) * 100).toFixed(1)
    : 0

  const costChartData = Object.entries(costSummary).map(([name, value]) => ({
    name, 금액: Number(value)
  }))

  return (
    <div className="project-detail">
      {/* 상단 헤더 */}
      <div className="page-header">
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <Link to="/projects" style={{ color: '#888', textDecoration: 'none', fontSize: 13 }}>← 프로젝트 목록</Link>
          </div>
          <div className="page-title" style={{ marginTop: 4 }}>
            {project.projectName}
            <span className={`badge ${st.cls}`} style={{ marginLeft: 10, fontSize: 13 }}>{st.label}</span>
          </div>
          <div className="page-subtitle">{project.projectCode} · {project.location}</div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="btn btn-danger" onClick={handleDelete}>삭제</button>
        </div>
      </div>

      {/* 요약 카드 */}
      <div className="project-summary">
        <div className="summary-item">
          <div className="summary-label">계약금액</div>
          <div className="summary-value">{formatAmount(project.contractAmount)}</div>
        </div>
        <div className="summary-item">
          <div className="summary-label">예산</div>
          <div className="summary-value">{formatAmount(project.budget)}</div>
        </div>
        <div className="summary-item">
          <div className="summary-label">실행예산</div>
          <div className="summary-value">{formatAmount(project.executionBudget)}</div>
        </div>
        <div className="summary-item">
          <div className="summary-label">실투입 원가</div>
          <div className="summary-value" style={{ color: Number(budgetUtilization) > 90 ? '#ff4d4f' : '#1a1a2e' }}>
            {formatAmount(project.actualCost)}
          </div>
          <div style={{ fontSize: 11, color: '#888' }}>예산 대비 {budgetUtilization}%</div>
        </div>
        <div className="summary-item">
          <div className="summary-label">공정률</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
            {editProgress ? (
              <>
                <input type="number" min="0" max="100" value={newProgress}
                  onChange={e => setNewProgress(Number(e.target.value))}
                  style={{ width: 60, padding: '4px 8px', border: '1px solid #d9d9d9', borderRadius: 4 }} />
                <span>%</span>
                <button className="btn btn-primary" style={{ padding: '4px 10px', fontSize: 12 }} onClick={handleProgressUpdate}>저장</button>
                <button className="btn btn-default" style={{ padding: '4px 10px', fontSize: 12 }} onClick={() => setEditProgress(false)}>취소</button>
              </>
            ) : (
              <>
                <div className="progress-bar" style={{ width: 100 }}>
                  <div className="progress-fill"
                    style={{ width: `${project.progressRate}%`, background: '#1677ff' }} />
                </div>
                <span style={{ fontWeight: 700, color: '#1677ff' }}>{project.progressRate}%</span>
                <button className="btn btn-default" style={{ padding: '3px 8px', fontSize: 11 }}
                  onClick={() => setEditProgress(true)}>수정</button>
              </>
            )}
          </div>
        </div>
        <div className="summary-item">
          <div className="summary-label">발주처</div>
          <div className="summary-value" style={{ fontSize: 14 }}>{project.client}</div>
        </div>
        <div className="summary-item">
          <div className="summary-label">착공 ~ 준공예정</div>
          <div className="summary-value" style={{ fontSize: 13 }}>
            {formatDate(project.startDate)} ~ {formatDate(project.plannedEndDate)}
          </div>
        </div>
        <div className="summary-item">
          <div className="summary-label">현장소장</div>
          <div className="summary-value" style={{ fontSize: 14 }}>{project.siteManager}</div>
        </div>
      </div>

      {/* 탭 */}
      <div className="tabs">
        {[
          { key: 'info', label: '📌 프로젝트 정보' },
          { key: 'po', label: `📋 구매발주 (${purchaseOrders.length})` },
          { key: 'cost', label: `💰 원가현황 (${costEntries.length})` },
          { key: 'equipment', label: `🚜 투입장비 (${equipment.length})` },
        ].map(tab => (
          <button
            key={tab.key}
            className={`tab-btn ${activeTab === tab.key ? 'tab-active' : ''}`}
            onClick={() => setActiveTab(tab.key)}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* 탭 내용 */}
      <div className="card">
        {activeTab === 'info' && (
          <div className="form-grid-2">
            <InfoRow label="프로젝트 코드" value={project.projectCode} />
            <InfoRow label="공사 유형" value={project.projectType} />
            <InfoRow label="공사명" value={project.projectName} />
            <InfoRow label="발주처" value={project.client} />
            <InfoRow label="공사 위치" value={project.location} />
            <InfoRow label="현장소장" value={project.siteManager} />
            <InfoRow label="착공일" value={formatDate(project.startDate)} />
            <InfoRow label="준공 예정일" value={formatDate(project.plannedEndDate)} />
            <InfoRow label="실제 완료일" value={formatDate(project.actualEndDate)} />
            <InfoRow label="계약금액" value={formatAmount(project.contractAmount)} />
            <InfoRow label="예산" value={formatAmount(project.budget)} />
            <InfoRow label="실행예산" value={formatAmount(project.executionBudget)} />
          </div>
        )}

        {activeTab === 'po' && (
          <div className="table-wrap">
            {purchaseOrders.length === 0 ? (
              <div className="empty-state"><div className="empty-state-icon">📋</div><div>발주 내역이 없습니다</div></div>
            ) : (
              <table>
                <thead>
                  <tr>
                    <th>발주번호</th>
                    <th>공급업체</th>
                    <th>상태</th>
                    <th>발주일</th>
                    <th>납품요청일</th>
                    <th>금액</th>
                    <th>담당자</th>
                  </tr>
                </thead>
                <tbody>
                  {purchaseOrders.map(po => {
                    const ps = PO_STATUS[po.status] || {}
                    return (
                      <tr key={po.id}>
                        <td style={{ fontWeight: 600, color: '#1677ff' }}>{po.poNumber}</td>
                        <td>{po.vendorName}</td>
                        <td><span className={`badge ${ps.cls}`}>{ps.label}</span></td>
                        <td>{formatDate(po.orderDate)}</td>
                        <td>{formatDate(po.deliveryDate)}</td>
                        <td className="amount">{formatAmount(po.totalAmount)}</td>
                        <td>{po.purchaser}</td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            )}
          </div>
        )}

        {activeTab === 'cost' && (
          <div>
            {costChartData.length > 0 && (
              <div style={{ marginBottom: 24 }}>
                <div style={{ fontWeight: 600, marginBottom: 12 }}>원가 유형별 투입 현황</div>
                <ResponsiveContainer width="100%" height={200}>
                  <BarChart data={costChartData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                    <XAxis dataKey="name" tick={{ fontSize: 12 }} />
                    <YAxis tickFormatter={v => `${(v/100000000).toFixed(0)}억`} tick={{ fontSize: 11 }} />
                    <Tooltip formatter={v => formatAmount(v)} />
                    <Bar dataKey="금액" fill="#1677ff" radius={[4,4,0,0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}
            <div className="table-wrap">
              {costEntries.length === 0 ? (
                <div className="empty-state"><div className="empty-state-icon">💰</div><div>원가 내역이 없습니다</div></div>
              ) : (
                <table>
                  <thead>
                    <tr>
                      <th>전표번호</th>
                      <th>원가유형</th>
                      <th>계정항목</th>
                      <th>발생일</th>
                      <th>금액</th>
                      <th>적요</th>
                    </tr>
                  </thead>
                  <tbody>
                    {costEntries.map(c => (
                      <tr key={c.id}>
                        <td style={{ fontWeight: 600 }}>{c.entryNumber}</td>
                        <td>{c.costType}</td>
                        <td>{c.costAccount}</td>
                        <td>{formatDate(c.entryDate)}</td>
                        <td className="amount">{formatAmount(c.amount)}</td>
                        <td style={{ maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                          {c.description}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        )}

        {activeTab === 'equipment' && (
          <div className="table-wrap">
            {equipment.length === 0 ? (
              <div className="empty-state"><div className="empty-state-icon">🚜</div><div>투입된 장비가 없습니다</div></div>
            ) : (
              <table>
                <thead>
                  <tr>
                    <th>장비코드</th>
                    <th>장비명</th>
                    <th>유형</th>
                    <th>모델</th>
                    <th>임대여부</th>
                    <th>임대단가(일)</th>
                    <th>누적운영시간</th>
                  </tr>
                </thead>
                <tbody>
                  {equipment.map(e => (
                    <tr key={e.id}>
                      <td style={{ fontWeight: 600 }}>{e.equipmentCode}</td>
                      <td>{e.equipmentName}</td>
                      <td>{e.equipmentType}</td>
                      <td>{e.model}</td>
                      <td>{e.isRented ? '임대' : '자사'}</td>
                      <td className="amount">{e.rentalCostPerDay ? formatAmount(e.rentalCostPerDay) : '-'}</td>
                      <td>{e.totalOperatingHours}h</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        )}
      </div>
    </div>
  )
}

function InfoRow({ label, value }) {
  return (
    <div className="info-row">
      <div className="info-label">{label}</div>
      <div className="info-value">{value || '-'}</div>
    </div>
  )
}
