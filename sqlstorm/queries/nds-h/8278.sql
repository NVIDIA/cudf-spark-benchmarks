WITH SupplierOrders AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
    AND l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s_suppkey, s_name, total_revenue,
           RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM SupplierOrders
)
SELECT r.r_name AS region_name, COUNT(DISTINCT ts.s_suppkey) AS supplier_count,
       SUM(ts.total_revenue) AS total_revenue
FROM TopSuppliers ts
JOIN supplier s ON ts.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE ts.revenue_rank <= 10
GROUP BY r.r_name
ORDER BY total_revenue DESC;