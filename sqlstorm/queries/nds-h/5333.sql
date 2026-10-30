WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
TotalCost AS (
    SELECT sp.s_suppkey, sp.s_name, SUM(sp.ps_availqty * sp.ps_supplycost) AS total_cost
    FROM SupplierParts sp
    GROUP BY sp.s_suppkey, sp.s_name
),
TopSuppliers AS (
    SELECT s.s_nationkey, s.s_name, t.total_cost
    FROM TotalCost t
    JOIN supplier s ON t.s_suppkey = s.s_suppkey
    ORDER BY t.total_cost DESC
    LIMIT 5
)
SELECT n.n_name, ts.s_name, ts.total_cost 
FROM TopSuppliers ts
JOIN nation n ON ts.s_nationkey = n.n_nationkey
WHERE n.n_name IN ('USA', 'Germany', 'China')
ORDER BY ts.total_cost DESC;
