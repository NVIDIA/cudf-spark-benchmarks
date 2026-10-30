
WITH SupplierOrderCount AS (
    SELECT s.s_suppkey, COUNT(o.o_orderkey) AS order_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey
),
PartRevenue AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate < DATE '1997-01-01' 
    GROUP BY p.p_partkey
),
RevenueRanked AS (
    SELECT pr.p_partkey, pr.total_revenue, 
           RANK() OVER (ORDER BY pr.total_revenue DESC) AS revenue_rank
    FROM PartRevenue pr
)
SELECT r.r_name, 
       COALESCE(SOC.order_count, 0) AS supplier_order_count,
       COALESCE(RR.total_revenue, 0) AS part_total_revenue,
       RR.revenue_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierOrderCount SOC ON s.s_suppkey = SOC.s_suppkey
LEFT JOIN RevenueRanked RR ON RR.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_suppkey = s.s_suppkey
)
WHERE r.r_name LIKE '%west%'
AND (COALESCE(SOC.order_count, 0) > 10 OR COALESCE(RR.total_revenue, 0) > 10000)
ORDER BY r.r_name, RR.revenue_rank;
