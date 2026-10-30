WITH RegionOrders AS (
    SELECT r.r_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_name
),
TopRegions AS (
    SELECT r_name, total_orders, total_revenue,
           RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM RegionOrders
)
SELECT r_name, total_orders, total_revenue
FROM TopRegions
WHERE revenue_rank <= 5
ORDER BY total_revenue DESC;
