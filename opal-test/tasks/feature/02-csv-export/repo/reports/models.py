from dataclasses import dataclass, field
from typing import List, Dict, Any


@dataclass
class Report:
    title: str
    columns: List[str]
    rows: List[Dict[str, Any]]
