import { Outlet, NavLink, useLocation } from 'react-router-dom'
import ChatBot from './ChatBot'
import './Layout.css'

const navItems = [
  { to: '/dashboard', icon: '📊', label: '대시보드' },
  { to: '/projects', icon: '🏗️', label: 'PS - 프로젝트' },
  { to: '/purchase-orders', icon: '📋', label: 'MM - 구매발주' },
  { to: '/materials', icon: '🧱', label: 'MM - 자재관리' },
  { to: '/equipment', icon: '🚜', label: 'PM - 장비관리' },
  { to: '/cost', icon: '💰', label: 'CO - 원가관리' },
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
          {navItems.map(item => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) => `nav-item ${isActive ? 'nav-item-active' : ''}`}
            >
              <span className="nav-icon">{item.icon}</span>
              <span className="nav-label">{item.label}</span>
            </NavLink>
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
