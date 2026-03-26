import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { projectApi, costApi, formatAmount } from '../api/api'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend
} from 'recharts'
import './Dashboard.css'

const COLORS = ['#1677ff', '#52c41a', '#fa8c16', '#ff4d4f', '#722ed1', '#13c2c2']

export default function Dashboard() {
  const [stats, setStats] = useState(null)
  const [projects, setProjects] = useState([])
  const [costSummary, setCostSummary] = useState({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      projectApi.getStats(),
      projectApi.getAll({ status: 'IN_PROGRESS' }),
      costApi.getSummary(),
    ]).then(([statsRes, projectsRes, costRes]) => {
      setStats(statsRes.data)
      setProjects(projectsRes.data.slice(0, 5))
      setCostSummary(costRes.data)
    }).finally(() => setLoading(false))
  }, [])

  if (loading) return <div className="loading">데이터 로딩 중...</div>

  const costChartData = Object.entries(costSummary).map(([name, value]) => ({
    name,
    금액: Number(value)
  }))

  const projectStatusData = [
    { name: '진행중', value: Number(stats?.inProgress || 0) },
    { name: '완료', value: Number(stats?.completed || 0) },
    { name: '계획', value: Number(stats?.planning || 0) },
  ].filter(d => d.value > 0)

  return (
    <div className="dashboard">
      <div className="page-header">
        <div>
          <div className="page-title">대시보드</div>
          <div className="page-subtitle">건설 SAP 시스템 현황</div>
        </div>
      </div>

      {/* 통계 카드 */}
      <div className="stat-cards">
        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#e6f4ff' }}>🏗️</div>
          <div className="stat-info">
            <div className="stat-value" style={{ color: '#1677ff' }}>{stats?.totalProjects}</div>
            <div className="stat-label">전체 프로젝트</div>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#f6ffed' }}>▶️</div>
          <div className="stat-info">
            <div className="stat-value" style={{ color: '#52c41a' }}>{stats?.inProgress}</div>
            <div className="stat-label">진행중 현장</div>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#fff7e6' }}>📋</div>
          <div className="stat-info">
            <div className="stat-value" style={{ color: '#fa8c16' }}>{stats?.planning}</div>
            <div className="stat-label">계획/수주 현장</div>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#f9f0ff' }}>💰</div>
          <div className="stat-info">
            <div className="stat-value" style={{ color: '#722ed1', fontSize: '16px' }}>
              {formatAmount(stats?.totalContractAmount)}
            </div>
            <div className="stat-label">진행중 계약총액</div>
          </div>
        </div>
      </div>

      {/* 차트 영역 */}
      <div className="dashboard-charts">
        <div className="card chart-card">
          <div className="chart-title">원가 유형별 현황</div>
          {costChartData.length > 0 ? (
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={costChartData} margin={{ top: 10, right: 10, left: 20, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="name" tick={{ fontSize: 12 }} />
                <YAxis tickFormatter={v => `${(v/100000000).toFixed(0)}억`} tick={{ fontSize: 11 }} />
                <Tooltip formatter={v => formatAmount(v)} />
                <Bar dataKey="금액" fill="#1677ff" radius={[4,4,0,0]} />
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="empty-state">원가 데이터가 없습니다</div>
          )}
        </div>

        <div className="card chart-card">
          <div className="chart-title">프로젝트 상태 현황</div>
          {projectStatusData.length > 0 ? (
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie
                  data={projectStatusData}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  outerRadius={90}
                  label={({ name, value }) => `${name}(${value})`}
                >
                  {projectStatusData.map((_, i) => (
                    <Cell key={i} fill={COLORS[i % COLORS.length]} />
                  ))}
                </Pie>
                <Legend />
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="empty-state">프로젝트 데이터가 없습니다</div>
          )}
        </div>
      </div>

      {/* 진행중 프로젝트 목록 */}
      <div className="card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <div className="chart-title" style={{ marginBottom: 0 }}>진행중 공사 현장</div>
          <Link to="/projects" className="btn btn-default" style={{ fontSize: 12 }}>전체보기</Link>
        </div>
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>프로젝트 코드</th>
                <th>공사명</th>
                <th>발주처</th>
                <th>계약금액</th>
                <th>공정률</th>
                <th>현장소장</th>
              </tr>
            </thead>
            <tbody>
              {projects.length === 0 ? (
                <tr><td colSpan="6" className="empty-state">진행중인 프로젝트가 없습니다</td></tr>
              ) : projects.map(p => (
                <tr key={p.id}>
                  <td>
                    <Link to={`/projects/${p.id}`} style={{ color: '#1677ff', textDecoration: 'none', fontWeight: 500 }}>
                      {p.projectCode}
                    </Link>
                  </td>
                  <td>{p.projectName}</td>
                  <td>{p.client}</td>
                  <td className="amount">{formatAmount(p.contractAmount)}</td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <div className="progress-bar" style={{ width: 80 }}>
                        <div
                          className="progress-fill"
                          style={{
                            width: `${p.progressRate}%`,
                            background: p.progressRate >= 80 ? '#52c41a' : p.progressRate >= 50 ? '#1677ff' : '#fa8c16'
                          }}
                        />
                      </div>
                      <span>{p.progressRate}%</span>
                    </div>
                  </td>
                  <td>{p.siteManager}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
