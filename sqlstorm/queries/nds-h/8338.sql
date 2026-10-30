
WITH regional_summary AS (
    SELECT r.r_name AS region_name,
           COUNT(DISTINCT c.c_custkey) AS customer_count,
           SUM(o.o_totalprice) AS total_revenue,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY r.r_name
),
high_revenue_regions AS (
    SELECT region_name,
           total_revenue,
           RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM regional_summary
    WHERE total_revenue > (SELECT AVG(total_revenue) FROM regional_summary)
)
SELECT r.region_name,
       r.customer_count,
       r.total_revenue,
       r.total_supply_cost,
       (r.total_revenue / NULLIF(r.total_supply_cost, 0)) AS profitability_ratio
FROM regional_summary r
JOIN high_revenue_regions hr ON r.region_name = hr.region_name
WHERE hr.revenue_rank <= 5
ORDER BY r.total_revenue DESC;
