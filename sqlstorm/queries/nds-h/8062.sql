
WITH SupplierRevenue AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT r.s_suppkey, r.s_name, r.revenue,
           RANK() OVER (ORDER BY r.revenue DESC) AS revenue_rank
    FROM SupplierRevenue r
)
SELECT n.n_name, SUM(rs.revenue) AS total_revenue
FROM RankedSuppliers rs
JOIN supplier s ON rs.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE rs.revenue_rank <= 10
GROUP BY n.n_name
ORDER BY total_revenue DESC;
