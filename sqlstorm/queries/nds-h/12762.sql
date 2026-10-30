WITH SupplierParts AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sp.TotalSupplyCost
    FROM supplier s
    JOIN SupplierParts sp ON s.s_suppkey = sp.s_suppkey
    ORDER BY sp.TotalSupplyCost DESC
    LIMIT 10
)

SELECT ts.s_suppkey, ts.s_name, ts.TotalSupplyCost
FROM TopSuppliers ts
ORDER BY ts.TotalSupplyCost;
