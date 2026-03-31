class Model:
    _table = None
    _fields = []

    def __init__(self, conn, **kwargs):
        self._conn = conn
        for field in self._fields:
            setattr(self, field, kwargs.get(field))

    def save(self):
        if hasattr(self, 'id') and self.id is not None:
            set_clause = ", ".join(f"{f} = ?" for f in self._fields if f != 'id')
            values = [getattr(self, f) for f in self._fields if f != 'id'] + [self.id]
            self._conn.execute(f"UPDATE {self._table} SET {set_clause} WHERE id = ?", values)
        else:
            fields = [f for f in self._fields if f != 'id']
            placeholders = ", ".join("?" for _ in fields)
            field_names = ", ".join(fields)
            values = [getattr(self, f) for f in fields]
            cursor = self._conn.execute(
                f"INSERT INTO {self._table} ({field_names}) VALUES ({placeholders})", values
            )
            self.id = cursor.lastrowid
        self._conn.commit()
        return self

    def delete(self):
        self._conn.execute(f"DELETE FROM {self._table} WHERE id = ?", (self.id,))
        self._conn.commit()

    @classmethod
    def find(cls, conn, record_id):
        row = conn.execute(f"SELECT * FROM {cls._table} WHERE id = ?", (record_id,)).fetchone()
        if row is None:
            return None
        return cls(conn, **dict(row))

    @classmethod
    def all(cls, conn, **filters):
        if filters:
            where = " AND ".join(f"{k} = ?" for k in filters)
            values = list(filters.values())
            rows = conn.execute(f"SELECT * FROM {cls._table} WHERE {where}", values).fetchall()
        else:
            rows = conn.execute(f"SELECT * FROM {cls._table}").fetchall()
        return [cls(conn, **dict(r)) for r in rows]

    def to_dict(self):
        return {f: getattr(self, f) for f in self._fields}
