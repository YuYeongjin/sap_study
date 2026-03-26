import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'

const AGENT_BADGES = {
  CHAT:       { label: '대화',      color: '#3b82f6' },
  RAG:        { label: '지식 검색', color: '#8b5cf6' },
  NAVIGATION: { label: '화면 이동', color: '#10b981' },
  DATA_QUERY: { label: '데이터 조회', color: '#f59e0b' },
  ERROR:      { label: '오류',      color: '#ef4444' },
}

const QUICK_ACTIONS = [
  '프로젝트 현황 알려줘',
  'SAP PS 모듈이란?',
  '자재 화면으로 이동해줘',
  '원가 관리 화면 열어줘',
]

const WELCOME_MSG = {
  role: 'assistant',
  content: '안녕하세요! SAP 건설 관리 시스템 AI 어시스턴트입니다.\n\n💬 SAP 모듈 질문, 데이터 조회, 화면 이동까지 도와드립니다.\n\n예) "SAP MM 모듈이 뭐야?", "프로젝트 현황 보여줘", "장비 관리 화면으로 이동해줘"',
  agentType: 'CHAT',
}

export default function ChatBot() {
  const [open, setOpen] = useState(false)
  const [messages, setMessages] = useState([WELCOME_MSG])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const [status, setStatus] = useState(null)
  const bottomRef = useRef(null)
  const inputRef = useRef(null)
  const navigate = useNavigate()

  // Ollama 상태 체크
  useEffect(() => {
    axios.get('/api/ai/status')
      .then(r => setStatus(r.data))
      .catch(() => setStatus({ available: false, model: 'llama3.1' }))
  }, [])

  // 스크롤 자동 이동
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, loading])

  // 패널 열릴 때 입력창 포커스
  useEffect(() => {
    if (open) setTimeout(() => inputRef.current?.focus(), 100)
  }, [open])

  async function sendMessage(text) {
    const msg = (text || input).trim()
    if (!msg || loading) return
    setInput('')

    const userMsg = { role: 'user', content: msg }
    setMessages(prev => [...prev, userMsg])
    setLoading(true)

    try {
      const history = messages
        .filter(m => m.role !== 'system')
        .slice(-8)
        .map(({ role, content }) => ({ role, content }))

      const { data } = await axios.post('/api/ai/chat', { message: msg, history })

      // 네비게이션 처리
      if (data.navigation?.path) {
        navigate(data.navigation.path)
      }

      setMessages(prev => [...prev, {
        role: 'assistant',
        content: data.message || '응답 없음',
        agentType: data.agentType,
        sources: data.sources,
        navigation: data.navigation,
      }])
    } catch (err) {
      setMessages(prev => [...prev, {
        role: 'assistant',
        content: `연결 오류가 발생했습니다.\nOllama가 실행 중인지 확인해주세요.\n\n오류: ${err.response?.data?.error || err.message}`,
        agentType: 'ERROR',
      }])
    } finally {
      setLoading(false)
    }
  }

  function handleKeyDown(e) {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage() }
  }

  function clearChat() {
    setMessages([WELCOME_MSG])
  }

  return (
    <>
      {/* ── 플로팅 버튼 ── */}
      <button
        onClick={() => setOpen(v => !v)}
        style={{
          position: 'fixed', bottom: 28, right: 28,
          width: 56, height: 56, borderRadius: '50%',
          background: open ? '#374151' : 'linear-gradient(135deg,#1d4ed8,#4f46e5)',
          color: '#fff', border: 'none', cursor: 'pointer',
          fontSize: 22, boxShadow: '0 4px 16px rgba(79,70,229,.45)',
          zIndex: 1200, display: 'flex', alignItems: 'center', justifyContent: 'center',
          transition: 'all .2s',
        }}
        title="AI 어시스턴트"
      >
        {open ? '✕' : '🤖'}
      </button>

      {/* ── 채팅 패널 ── */}
      {open && (
        <div style={{
          position: 'fixed', bottom: 96, right: 28,
          width: 400, height: 600,
          background: '#fff', borderRadius: 20,
          boxShadow: '0 12px 48px rgba(0,0,0,.18)',
          display: 'flex', flexDirection: 'column',
          zIndex: 1199, overflow: 'hidden',
          border: '1px solid rgba(0,0,0,.08)',
        }}>

          {/* 헤더 */}
          <div style={{
            padding: '14px 16px',
            background: 'linear-gradient(135deg,#1e3a8a,#4f46e5)',
            color: '#fff', flexShrink: 0,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <span style={{ fontSize: 22 }}>🤖</span>
                <div>
                  <div style={{ fontWeight: 700, fontSize: 15 }}>SAP AI 어시스턴트</div>
                  <div style={{ fontSize: 11, opacity: .8, marginTop: 1 }}>
                    {status?.available
                      ? `✓ ${status.model} 연결됨`
                      : '⚠ Ollama 연결 확인 중...'}
                  </div>
                </div>
              </div>
              <div style={{ display: 'flex', gap: 6 }}>
                <button
                  onClick={clearChat}
                  style={{
                    background: 'rgba(255,255,255,.15)', border: 'none',
                    color: '#fff', borderRadius: 8, padding: '4px 10px',
                    cursor: 'pointer', fontSize: 11,
                  }}
                  title="대화 초기화"
                >초기화</button>
              </div>
            </div>

            {/* Agent 유형 범례 */}
            <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
              {Object.entries(AGENT_BADGES).filter(([k]) => k !== 'ERROR').map(([key, { label, color }]) => (
                <span key={key} style={{
                  fontSize: 10, padding: '2px 7px', borderRadius: 10,
                  background: color + '30', border: `1px solid ${color}50`,
                  color: '#fff',
                }}>{label}</span>
              ))}
            </div>
          </div>

          {/* 메시지 영역 */}
          <div style={{
            flex: 1, overflowY: 'auto', padding: '12px 12px 4px',
            display: 'flex', flexDirection: 'column', gap: 10,
          }}>
            {messages.map((m, i) => (
              <MessageBubble key={i} msg={m} />
            ))}

            {loading && (
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 6 }}>
                <span style={{ fontSize: 18 }}>🤖</span>
                <div style={{
                  padding: '10px 14px', borderRadius: '4px 16px 16px 16px',
                  background: '#f3f4f6', color: '#6b7280', fontSize: 13,
                }}>
                  <ThinkingDots />
                </div>
              </div>
            )}
            <div ref={bottomRef} />
          </div>

          {/* 빠른 질문 */}
          <div style={{
            padding: '8px 12px',
            borderTop: '1px solid #e5e7eb',
            display: 'flex', gap: 6, flexWrap: 'wrap',
            flexShrink: 0,
          }}>
            {QUICK_ACTIONS.map(q => (
              <button
                key={q}
                onClick={() => sendMessage(q)}
                disabled={loading}
                style={{
                  padding: '4px 10px', borderRadius: 12,
                  border: '1px solid #d1d5db', background: '#fafafa',
                  color: '#374151', fontSize: 11, cursor: 'pointer',
                  transition: 'all .15s',
                }}
              >{q}</button>
            ))}
          </div>

          {/* 입력창 */}
          <div style={{
            padding: '10px 12px',
            borderTop: '1px solid #e5e7eb',
            display: 'flex', gap: 8,
            flexShrink: 0,
          }}>
            <textarea
              ref={inputRef}
              value={input}
              onChange={e => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="메시지 입력... (Enter 전송 / Shift+Enter 줄바꿈)"
              disabled={loading}
              rows={2}
              style={{
                flex: 1, padding: '8px 12px', borderRadius: 10,
                border: '1px solid #d1d5db', fontSize: 13, resize: 'none',
                outline: 'none', fontFamily: 'inherit', lineHeight: 1.5,
              }}
            />
            <button
              onClick={() => sendMessage()}
              disabled={loading || !input.trim()}
              style={{
                width: 42, borderRadius: 10,
                background: (loading || !input.trim()) ? '#d1d5db' : 'linear-gradient(135deg,#1d4ed8,#4f46e5)',
                color: '#fff', border: 'none',
                cursor: (loading || !input.trim()) ? 'not-allowed' : 'pointer',
                fontSize: 18, flexShrink: 0,
              }}
            >↑</button>
          </div>
        </div>
      )}
    </>
  )
}

// ── 메시지 버블 ────────────────────────────────────────────────────────
function MessageBubble({ msg }) {
  const isUser = msg.role === 'user'
  const badge = msg.agentType ? AGENT_BADGES[msg.agentType] : null

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: isUser ? 'flex-end' : 'flex-start' }}>
      {/* Agent 배지 (어시스턴트 메시지) */}
      {badge && !isUser && (
        <span style={{
          fontSize: 10, padding: '2px 7px', borderRadius: 10, marginBottom: 3,
          background: badge.color + '18', border: `1px solid ${badge.color}40`,
          color: badge.color, fontWeight: 600,
        }}>
          {badge.label}
        </span>
      )}

      <div style={{
        maxWidth: '86%',
        padding: '10px 14px',
        borderRadius: isUser ? '16px 16px 4px 16px' : '4px 16px 16px 16px',
        background: isUser ? 'linear-gradient(135deg,#1d4ed8,#4f46e5)' : '#f3f4f6',
        color: isUser ? '#fff' : '#1f2937',
        fontSize: 13, lineHeight: 1.6, whiteSpace: 'pre-wrap',
        wordBreak: 'break-word',
      }}>
        {msg.content}
      </div>

      {/* RAG 출처 */}
      {msg.sources?.length > 0 && (
        <div style={{ fontSize: 10, color: '#9ca3af', marginTop: 3, maxWidth: '86%' }}>
          📚 출처: {msg.sources.join(' · ')}
        </div>
      )}

      {/* 네비게이션 결과 */}
      {msg.navigation?.path && (
        <div style={{ fontSize: 11, color: '#10b981', marginTop: 3, fontWeight: 600 }}>
          → {msg.navigation.label}으로 이동됨
        </div>
      )}
    </div>
  )
}

// ── 타이핑 애니메이션 ──────────────────────────────────────────────────
function ThinkingDots() {
  const [dots, setDots] = useState('.')
  useEffect(() => {
    const id = setInterval(() => setDots(d => d.length >= 3 ? '.' : d + '.'), 400)
    return () => clearInterval(id)
  }, [])
  return <span>생각 중{dots}</span>
}
