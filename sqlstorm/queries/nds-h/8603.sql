WITH region_orders AS (
    SELECT r.r_name, count(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_name
)
SELECT r.r_name, ro.total_orders, ro.total_revenue,
       (ro.total_revenue / ro.total_orders) AS avg_order_value,
       RANK() OVER (ORDER BY ro.total_revenue DESC) AS revenue_rank
FROM region_orders ro
JOIN region r ON r.r_name = ro.r_name
WHERE ro.total_orders > 0
ORDER BY revenue_rank;
