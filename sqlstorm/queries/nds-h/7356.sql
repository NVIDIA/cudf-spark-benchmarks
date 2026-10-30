WITH SupplierOrders AS (
    SELECT s.s_suppkey, s.s_name, SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem ol ON ps.ps_partkey = ol.l_partkey
    JOIN orders o ON ol.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, so.total_revenue,
           RANK() OVER (ORDER BY so.total_revenue DESC) AS revenue_rank
    FROM SupplierOrders so
    JOIN supplier s ON so.s_suppkey = s.s_suppkey
)
SELECT r.s_suppkey, r.s_name, r.total_revenue
FROM RankedSuppliers r
WHERE r.revenue_rank <= 10
ORDER BY r.total_revenue DESC;