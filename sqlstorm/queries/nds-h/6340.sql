WITH SupplierRevenue AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * l.l_quantity) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sr.total_revenue
    FROM SupplierRevenue sr
    JOIN supplier s ON sr.s_suppkey = s.s_suppkey
    WHERE sr.total_revenue > (SELECT AVG(total_revenue) FROM SupplierRevenue)
)
SELECT
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT ts.s_suppkey) AS supplier_count,
    SUM(ts.total_revenue) AS total_revenue
FROM TopSuppliers ts
JOIN supplier s ON ts.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY n.n_name, r.r_name
ORDER BY total_revenue DESC
LIMIT 10;
