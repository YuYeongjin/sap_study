import { Outlet, NavLink, useLocation } from 'react-router-dom'
import ChatBot from './ChatBot'
import './Layout.css'

const navSections = [
  {
    label: null,
    items: [
      { to: '/dashboard', icon: '📊', label: '대시보드' },
    ]
  },
  {
    label: 'PS / MM / PM',
    items: [
      { to: '/projects', icon: '🏗️', label: 'PS - 프로젝트' },
      { to: '/purchase-orders', icon: '📋', label: 'MM - 구매발주' },
      { to: '/materials', icon: '🧱', label: 'MM - 자재관리' },
      { to: '/equipment', icon: '🚜', label: 'PM - 장비관리' },
      { to: '/cost', icon: '📁', label: 'CO - 원가입력' },
    ]
  },
  {
    label: 'FI 재무회계',
    items: [
      { to: '/fi/ar', icon: '📥', label: 'FI - 매출채권' },
      { to: '/fi/ap', icon: '📤', label: 'FI - 매입채무' },
      { to: '/fi/gl', icon: '📒', label: 'FI - 총계정원장' },
      { to: '/fi/assets', icon: '🏛️', label: 'FI - 고정자산' },
    ]
  },
  {
    label: 'CO 관리회계',
    items: [
      { to: '/co/costcenter', icon: '🏢', label: 'CO - 코스트센터' },
      { to: '/co/orders', icon: '📑', label: 'CO - 내부오더' },
      { to: '/co/profitcenter', icon: '💹', label: 'CO - 손익센터' },
    ]
  },
]

export default function Layout() {
  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="sidebar-logo">
          <div className="logo-icon">🏢</div>
          <div className="logo-text">
            <div className="logo-title">건설 SAP</div>
            <div className="logo-subtitle">Construction ERP</div>
          </div>
        </div>

        <nav className="sidebar-nav">
          {navSections.map((section, si) => (
            <div key={si} className="nav-section">
              {section.label && (
                <div className="nav-section-label">{section.label}</div>
              )}
              {section.items.map(item => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  className={({ isActive }) => `nav-item ${isActive ? 'nav-item-active' : ''}`}
                >
                  <span className="nav-icon">{item.icon}</span>
                  <span className="nav-label">{item.label}</span>
                </NavLink>
              ))}
            </div>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="sidebar-user">
            <div className="user-avatar">👤</div>
            <div>
              <div className="user-name">관리자</div>
              <div className="user-role">SAP 학습 프로젝트</div>
            </div>
          </div>
        </div>
      </aside>

      <main className="main-content">
        <Outlet />
      </main>

      <ChatBot />
    </div>
  )
}
