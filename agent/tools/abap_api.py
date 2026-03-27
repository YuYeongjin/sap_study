"""
ABAP REST API 호출 도구
ZCL_REST_PROJECT/MATERIAL/EQUIPMENT 등 호출 후 요약 문자열 반환.
"""

import httpx
from ..config import ABAP_BASE_URL, ABAP_AUTH


def _get(path: str, params: dict = None) -> list | dict | None:
    url = f"{ABAP_BASE_URL}/{path.lstrip('/')}"
    try:
        resp = httpx.get(url, params=params, auth=ABAP_AUTH, timeout=10)
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        return None


def fetch_projects(status: str = None) -> str:
    params = {"status": status} if status else {}
    data   = _get("projects", params)
    if not data:
        return "프로젝트 데이터를 가져올 수 없습니다."

    if isinstance(data, dict):   # 단건 또는 에러
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
    data = _get("projects", {"stats": 1})
    if not data:
        return "통계 데이터를 가져올 수 없습니다."
    return (
        f"[프로젝트 통계]\n"
        f"- 전체: {data.get('totalProjects',0)}건\n"
        f"- 진행중: {data.get('inProgressCount',0)}건\n"
        f"- 완료: {data.get('completedCount',0)}건\n"
        f"- 계획: {data.get('planningCount',0)}건\n"
        f"- 총 계약금액: {data.get('totalContractAmt',0):,}원"
    )


def fetch_materials(low_stock_only: bool = False) -> str:
    params = {"lowstock": 1} if low_stock_only else {}
    data   = _get("materials", params)
    if not data:
        return "자재 데이터를 가져올 수 없습니다."

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
    data   = _get("equipment", params)
    if not data:
        return "장비 데이터를 가져올 수 없습니다."

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
        data = _get("cost-entries", {"project_id": project_id, "summary": 1})
    else:
        data = _get("cost-entries", {"all_summary": 1})
    if not data:
        return "원가 데이터를 가져올 수 없습니다."

    if isinstance(data, dict):
        data = [data]

    lines = ["[원가 요약]"]
    for c in data:
        lines.append(
            f"- 프로젝트 {c.get('projectId','?')} | 유형: {c.get('costType','?')} "
            f"| 합계: {c.get('totalAmount',0):,}원 ({c.get('entryCount',0)}건)"
        )
    return "\n".join(lines)


def fetch_purchase_orders(status: str = None) -> str:
    params = {"status": status} if status else {}
    data   = _get("purchase-orders", params)
    if not data:
        return "구매발주 데이터를 가져올 수 없습니다."

    if isinstance(data, dict):
        data = [data]

    lines = ["[구매발주 현황]"]
    for po in data[:10]:
        lines.append(
            f"- {po.get('poNumber','?')} | {po.get('vendorName','?')} "
            f"| 상태: {po.get('status','?')} | 금액: {po.get('totalAmount',0):,}원"
        )
    if len(data) > 10:
        lines.append(f"... 외 {len(data)-10}건")
    return "\n".join(lines)
