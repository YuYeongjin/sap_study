"""
CRUD Node
자연어 메시지에서 엔티티·작업·데이터를 추출해 ABAP REST API로 CRUD 실행.

흐름:
  1. LLM이 메시지를 JSON 구조로 파싱 (entity / operation / data / id)
  2. 해당 ABAP API 호출
  3. 결과를 자연어로 응답
"""

import json
import re

from langchain_ollama import ChatOllama
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.messages import HumanMessage, SystemMessage

from graph.state import AgentState
from config import OLLAMA_BASE_URL, OLLAMA_MODEL
import tools.abap_api as api


# ── 1단계: LLM으로 구조화 파싱 ──────────────────────────────────────

_EXTRACT_PROMPT = ChatPromptTemplate.from_messages([
    ("system", """You are a data extraction assistant for a SAP construction ERP chatbot.
Extract the CRUD operation from the user's Korean message and return ONLY valid JSON.

Entities: project, material, equipment, purchase_order, cost_entry
Operations: create, update, delete

For update/delete, extract the target "id" if mentioned (numeric string).
For PO status update, use operation "update_status" and put new status in data.status.
For equipment assignment, use operation "assign" with data.project_id.

Status values:
- project: PLANNING, BIDDING, CONTRACTED, IN_PROGRESS, COMPLETED, SUSPENDED
- equipment: AVAILABLE, IN_USE, MAINTENANCE, BROKEN, DISPOSED
- purchase_order: DRAFT, PENDING, APPROVED, ORDERED, PARTIAL_RECEIVED, RECEIVED, CANCELLED

Project types: CIVIL, BUILDING, PLANT, ELECTRICAL, MECHANICAL
Cost types: LABOR, MATERIAL, EQUIPMENT_COST, SUBCONTRACT, OVERHEAD, INDIRECT

Return JSON format:
{
  "entity": "<entity>",
  "operation": "<create|update|update_status|assign|delete>",
  "id": "<id or null>",
  "data": { <field: value pairs extracted from message> }
}

If you cannot determine the operation clearly, return:
{"entity": null, "operation": null, "id": null, "data": {}}
"""),
    ("human", "{message}"),
])


def _extract_intent(message: str) -> dict:
    llm    = ChatOllama(base_url=OLLAMA_BASE_URL, model=OLLAMA_MODEL, temperature=0)
    chain  = _EXTRACT_PROMPT | llm
    result = chain.invoke({"message": message})
    raw    = result.content.strip()

    # JSON 블록 추출
    json_match = re.search(r'\{.*\}', raw, re.DOTALL)
    if json_match:
        try:
            return json.loads(json_match.group())
        except json.JSONDecodeError:
            pass
    return {"entity": None, "operation": None, "id": None, "data": {}}


# ── 2단계: ABAP API 실행 ─────────────────────────────────────────────

def _execute(entity: str, operation: str, id: str | None, data: dict) -> tuple[bool, str]:
    """(success, message) 반환"""

    match (entity, operation):
        # --- 프로젝트 ---
        case ("project", "create"):
            r = api.create_project(data)
            return _result(r, f"프로젝트 '{data.get('projectName','?')}'가 생성되었습니다.")
        case ("project", "update"):
            r = api.update_project(id, data)
            return _result(r, f"프로젝트 {id}가 수정되었습니다.")
        case ("project", "delete"):
            r = api.delete_project(id)
            return _result(r, f"프로젝트 {id}가 삭제되었습니다.")

        # --- 자재 ---
        case ("material", "create"):
            r = api.create_material(data)
            return _result(r, f"자재 '{data.get('materialName','?')}'가 등록되었습니다.")
        case ("material", "update"):
            r = api.update_material(id, data)
            return _result(r, f"자재 {id}가 수정되었습니다.")
        case ("material", "delete"):
            r = api.delete_material(id)
            return _result(r, f"자재 {id}가 삭제되었습니다.")

        # --- 장비 ---
        case ("equipment", "create"):
            r = api.create_equipment(data)
            return _result(r, f"장비 '{data.get('equipmentName','?')}'가 등록되었습니다.")
        case ("equipment", "update"):
            r = api.update_equipment(id, data)
            return _result(r, f"장비 {id}가 수정되었습니다.")
        case ("equipment", "assign"):
            r = api.assign_equipment(id, data.get("project_id", ""))
            return _result(r, f"장비 {id}를 프로젝트 {data.get('project_id')}에 배정했습니다.")
        case ("equipment", "delete"):
            r = api.delete_equipment(id)
            return _result(r, f"장비 {id}가 삭제되었습니다.")

        # --- 구매발주 ---
        case ("purchase_order", "create"):
            r = api.create_purchase_order(data)
            return _result(r, f"구매발주 '{data.get('poNumber','?')}'가 생성되었습니다.")
        case ("purchase_order", "update_status"):
            r = api.update_po_status(id, data.get("status", ""))
            return _result(r, f"발주 {id} 상태를 '{data.get('status')}'로 변경했습니다.")
        case ("purchase_order", "delete"):
            r = api.delete_purchase_order(id)
            return _result(r, f"발주 {id}가 삭제되었습니다.")

        # --- 원가전표 ---
        case ("cost_entry", "create"):
            r = api.create_cost_entry(data)
            return _result(r, f"원가전표가 생성되었습니다. (프로젝트 {data.get('projectId','?')})")
        case ("cost_entry", "delete"):
            r = api.delete_cost_entry(id)
            return _result(r, f"원가전표 {id}가 삭제되었습니다.")

        case _:
            return False, "요청을 정확히 이해하지 못했습니다. 좀 더 구체적으로 말씀해 주세요."


def _result(api_resp: dict, success_msg: str) -> tuple[bool, str]:
    if isinstance(api_resp, dict) and "error" in api_resp:
        return False, f"처리 실패: {api_resp['error']}"
    return True, success_msg


# ── 3단계: 자연어 응답 생성 ──────────────────────────────────────────

def _generate_response(message: str, success: bool, result_msg: str) -> str:
    llm = ChatOllama(base_url=OLLAMA_BASE_URL, model=OLLAMA_MODEL, temperature=0.3)
    status = "성공" if success else "실패"
    prompt = (
        f"사용자 요청: {message}\n"
        f"처리 결과 ({status}): {result_msg}\n\n"
        "위 결과를 바탕으로 사용자에게 친절하게 한국어로 결과를 알려주세요. "
        "성공이면 완료 메시지를, 실패면 원인과 도움말을 포함하세요."
    )
    resp = llm.invoke([HumanMessage(content=prompt)])
    return resp.content


# ── 메인 노드 ────────────────────────────────────────────────────────

def crud_node(state: AgentState) -> dict:
    message  = state["message"]
    parsed   = _extract_intent(message)

    entity    = parsed.get("entity")
    operation = parsed.get("operation")
    id_val    = parsed.get("id")
    data      = parsed.get("data", {})

    if not entity or not operation:
        return {
            "crud_result": "요청을 이해하지 못했습니다.",
            "response":    "어떤 데이터를 어떻게 처리할지 좀 더 구체적으로 말씀해 주세요.\n"
                           "예) '프로젝트 만들어줘, 이름은 부산항만공사, 발주처는 부산시'\n"
                           "예) '발주 3번 상태를 APPROVED로 변경해줘'\n"
                           "예) '자재 MM-STL-001 삭제해줘'",
            "agent_type":  "CRUD",
        }

    success, result_msg = _execute(entity, operation, id_val, data)
    response = _generate_response(message, success, result_msg)

    return {
        "crud_result": result_msg,
        "response":    response,
        "agent_type":  "CRUD",
    }
