from dataclasses import dataclass, field
import uuid


@dataclass
class Department:
    name: str
    id: str = field(default_factory=lambda: str(uuid.uuid4()))


@dataclass
class Team:
    name: str
    department_id: str
    id: str = field(default_factory=lambda: str(uuid.uuid4()))


@dataclass
class Employee:
    name: str
    team_id: str
    id: str = field(default_factory=lambda: str(uuid.uuid4()))


@dataclass
class Assignment:
    title: str
    employee_id: str
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
