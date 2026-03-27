"""
ABAP REST API 호출 도구 (GET / POST / PUT / DELETE)
ZCL_REST_PROJECT/MATERIAL/EQUIPMENT/PO/COST 연동.
"""

import httpx
from config import ABAP_BASE_URL, ABAP_AUTH


def _request(method: str, path: str, params: dict = None, json: dict = None):
    url = f"{ABAP_BASE_URL}/{path.lstrip('/')}"
    try:
        resp = httpx.request(
            method, url, params=params, json=json,
            auth=ABAP_AUTH, timeout=10,
        )
        resp.raise_for_status()
        if resp.content:
            return resp.json()
        return {"ok": True}
    except httpx.HTTPStatusError as e:
        return {"error": f"HTTP {e.response.status_code}: {e.response.text}"}
    except Exception as e:
        return {"error": str(e)}


# ── GET ──────────────────────────────────────────────────────────────

def fetch_projects(status: str = None) -> str:
    params = {"status": status} if status else {}
    data   = _request("GET", "projects", params=params)
    if isinstance(data, dict) and "error" in data:
        return f"프로젝트 조회 실패: {data['error']}"
    if isinstance(data, dict):
        data = [data]
    lines = ["[프로젝트 현황]"]
    for p in data[:10]:
        lines.append(
            f"- {p.get('projectCode','?')} | {p.get('projectName','?')} "
            f"| 상태: {p.get('status','?')} | 진행률: {p.get('progressRate','?')}%"
        )
    if len(data) > 10:
        lines.append(f"... 외 {len(data)-10}건")
    return "\n".join(lines)


def fetch_project_stats() -> str:
    data = _request("GET", "projects", params={"stats": 1})
    if isinstance(data, dict) and "error" in data:
        return f"통계 조회 실패: {data['error']}"
    return (
        f"[프로젝트 통계]\n"
        f"- 전체: {data.get('totalProjects',0)}건\n"
        f"- 진행중: {data.get('inProgressCount',0)}건\n"
        f"- 완료: {data.get('completedCount',0)}건\n"
        f"- 계약완료: {data.get('contractedCount',0)}건\n"
        f"- 계획: {data.get('planningCount',0)}건\n"
        f"- 총 계약금액: {data.get('totalContractAmt',0):,}원"
    )


def fetch_materials(low_stock_only: bool = False) -> str:
    params = {"lowstock": 1} if low_stock_only else {}
    data   = _request("GET", "materials", params=params)
    if isinstance(data, dict) and "error" in data:
        return f"자재 조회 실패: {data['error']}"
    if isinstance(data, dict):
        data = [data]
    label = "저재고 자재" if low_stock_only else "자재 현황"
    lines = [f"[{label}]"]
    for m in data[:10]:
        lines.append(
            f"- {m.get('materialCode','?')} | {m.get('materialName','?')} "
            f"| 재고: {m.get('stockQty','?')} {m.get('unit','?')} "
            f"(안전재고: {m.get('safetyStock','?')})"
        )
    if len(data) > 10:
        lines.append(f"... 외 {len(data)-10}건")
    return "\n".join(lines)


def fetch_equipment(status: str = None) -> str:
    params = {"status": status} if status else {}
    data   = _request("GET", "equipment", params=params)
    if isinstance(data, dict) and "error" in data:
        return f"장비 조회 실패: {data['error']}"
    if isinstance(data, dict):
        data = [data]
    lines = ["[장비 현황]"]
    for e in data[:10]:
        rented = "임대" if e.get("isRented") else "자사"
        lines.append(
            f"- {e.get('equipmentCode','?')} | {e.get('equipmentName','?')} "
            f"| 상태: {e.get('status','?')} | {rented}"
        )
    if len(data) > 10:
        lines.append(f"... 외 {len(data)-10}건")
    return "\n".join(lines)


def fetch_cost_summary(project_id: str = None) -> str:
    if project_id:
        data = _request("GET", "cost-entries", params={"project_id": project_id, "summary": 1})
    else:
        data = _request("GET", "cost-entries", params={"all_summary": 1})
    if isinstance(data, dict) and "error" in data:
        return f"원가 조회 실패: {data['error']}"
    if isinstance(data, dict):
        data = [data]
    lines = ["[원가 요약]"]
    for c in data:
        lines.append(
            f"- 프로젝트 {c.get('projectId','?')} | {c.get('costType','?')} "
            f"| {c.get('totalAmount',0):,}원 ({c.get('entryCount',0)}건)"
        )
    return "\n".join(lines)


def fetch_purchase_orders(status: str = None) -> str:
    params = {"status": status} if status else {}
    data   = _request("GET", "purchase-orders", params=params)
    if isinstance(data, dict) and "error" in data:
        return f"발주 조회 실패: {data['error']}"
    if isinstance(data, dict):
        data = [data]
    lines = ["[구매발주 현황]"]
    for po in data[:10]:
        lines.append(
            f"- {po.get('poNumber','?')} | {po.get('vendorName','?')} "
            f"| 상태: {po.get('status','?')} | {po.get('totalAmount',0):,}원"
        )
    if len(data) > 10:
        lines.append(f"... 외 {len(data)-10}건")
    return "\n".join(lines)


# ── CREATE ───────────────────────────────────────────────────────────

def create_project(payload: dict) -> dict:
    return _request("POST", "projects", json=payload)

def create_material(payload: dict) -> dict:
    return _request("POST", "materials", json=payload)

def create_equipment(payload: dict) -> dict:
    return _request("POST", "equipment", json=payload)

def create_purchase_order(payload: dict) -> dict:
    return _request("POST", "purchase-orders", json=payload)

def create_cost_entry(payload: dict) -> dict:
    return _request("POST", "cost-entries", json=payload)


# ── UPDATE ───────────────────────────────────────────────────────────

def update_project(id: str, payload: dict) -> dict:
    return _request("PUT", "projects", params={"id": id}, json=payload)

def update_material(id: str, payload: dict) -> dict:
    return _request("PUT", "materials", params={"id": id}, json=payload)

def update_equipment(id: str, payload: dict) -> dict:
    return _request("PUT", "equipment", params={"id": id}, json=payload)

def update_po_status(id: str, status: str) -> dict:
    return _request("PUT", "purchase-orders", params={"id": id, "status": status})

def assign_equipment(equipment_id: str, project_id: str) -> dict:
    return _request("PUT", "equipment", params={"id": equipment_id, "assign": project_id})


# ── DELETE ───────────────────────────────────────────────────────────

def delete_project(id: str) -> dict:
    return _request("DELETE", "projects", params={"id": id})

def delete_material(id: str) -> dict:
    return _request("DELETE", "materials", params={"id": id})

def delete_equipment(id: str) -> dict:
    return _request("DELETE", "equipment", params={"id": id})

def delete_purchase_order(id: str) -> dict:
    return _request("DELETE", "purchase-orders", params={"id": id})

def delete_cost_entry(id: str) -> dict:
    return _request("DELETE", "cost-entries", params={"id": id})
