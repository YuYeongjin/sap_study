import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import Layout from './components/Layout'
import Dashboard from './pages/Dashboard'
import Projects from './pages/Projects'
import ProjectDetail from './pages/ProjectDetail'
import PurchaseOrders from './pages/PurchaseOrders'
import Materials from './pages/Materials'
import Equipment from './pages/Equipment'
import CostManagement from './pages/CostManagement'

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
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
