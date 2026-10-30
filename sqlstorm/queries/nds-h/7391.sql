WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT ss.s_suppkey, ss.s_name, n.n_name AS nation_name, ss.total_cost
    FROM SupplierSummary ss
    JOIN nation n ON ss.s_nationkey = n.n_nationkey
    WHERE ss.total_cost > (SELECT AVG(total_cost) FROM SupplierSummary)
    ORDER BY ss.total_cost DESC
    LIMIT 10
)
SELECT ts.s_suppkey, ts.s_name, ts.nation_name, COUNT(o.o_orderkey) AS total_orders
FROM TopSuppliers ts
LEFT JOIN lineitem l ON l.l_suppkey = ts.s_suppkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
GROUP BY ts.s_suppkey, ts.s_name, ts.nation_name
ORDER BY total_orders DESC;
