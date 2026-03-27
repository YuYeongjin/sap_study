import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// SAP ABAP 서버 설정
// host: SAP 시스템 호스트명 또는 IP
// port: ICM HTTP 포트 (기본 8000)
// 인증이 필요한 경우 auth 주석 해제 후 계정 입력
const SAP_SERVER = {
  host: 'localhost',
  port: 4004 //8000,
  // auth: 'SAP_USER:SAP_PASSWORD',
}

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      // AI 챗봇 → Python FastAPI (LangGraph 멀티 에이전트)
      '/api/ai': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
      // 나머지 API는 ABAP 서버로 라우팅
      // /api/projects → /sap/bc/zconstruction/projects
      '/api': {
        target: `http://${SAP_SERVER.host}:${SAP_SERVER.port}`,
        // auth: SAP_SERVER.auth,
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, '/sap/bc/zconstruction'),
      },
    }
  }
})
