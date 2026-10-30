
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighCostSuppliers AS (
    SELECT r.r_regionkey, r.r_name, COUNT(rs.s_suppkey) AS supplier_count, SUM(rs.total_cost) AS total_supplier_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN RankedSuppliers rs ON n.n_nationkey = rs.s_suppkey
    WHERE rs.total_cost > 10000
    GROUP BY r.r_regionkey, r.r_name
)
SELECT r.r_name, hc.supplier_count, hc.total_supplier_cost
FROM region r
JOIN HighCostSuppliers hc ON r.r_regionkey = hc.r_regionkey
ORDER BY hc.total_supplier_cost DESC, hc.supplier_count DESC;
