import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import Layout from './components/Layout'
import Dashboard from './pages/Dashboard'
import Projects from './pages/Projects'
import ProjectDetail from './pages/ProjectDetail'
import PurchaseOrders from './pages/PurchaseOrders'
import Materials from './pages/Materials'
import Equipment from './pages/Equipment'
import CostManagement from './pages/CostManagement'
import FI_AR from './pages/FI_AR'
import FI_AP from './pages/FI_AP'
import FI_GL from './pages/FI_GL'
import FI_Assets from './pages/FI_Assets'
import CO_CostCenter from './pages/CO_CostCenter'
import CO_Orders from './pages/CO_Orders'
import CO_ProfitCenter from './pages/CO_ProfitCenter'

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<Dashboard />} />
          <Route path="projects" element={<Projects />} />
          <Route path="projects/:id" element={<ProjectDetail />} />
          <Route path="purchase-orders" element={<PurchaseOrders />} />
          <Route path="materials" element={<Materials />} />
          <Route path="equipment" element={<Equipment />} />
          <Route path="cost" element={<CostManagement />} />
          {/* FI - 재무회계 */}
          <Route path="fi/ar" element={<FI_AR />} />
          <Route path="fi/ap" element={<FI_AP />} />
          <Route path="fi/gl" element={<FI_GL />} />
          <Route path="fi/assets" element={<FI_Assets />} />
          {/* CO - 관리회계 */}
          <Route path="co/costcenter" element={<CO_CostCenter />} />
          <Route path="co/orders" element={<CO_Orders />} />
          <Route path="co/profitcenter" element={<CO_ProfitCenter />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
