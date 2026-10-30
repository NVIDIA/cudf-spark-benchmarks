WITH RegionSummary AS (
    SELECT r_name,
           SUM(CASE WHEN o_orderstatus = 'F' THEN l_extendedprice * (1 - l_discount) END) AS total_freight_revenue,
           COUNT(DISTINCT o_orderkey) AS total_orders
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY r_name
),
AverageRevenue as (
    SELECT AVG(total_freight_revenue) AS avg_revenue
    FROM RegionSummary
),
RankedRegions AS (
    SELECT r_name,
           total_freight_revenue,
           ROW_NUMBER() OVER (ORDER BY total_freight_revenue DESC) AS revenue_rank
    FROM RegionSummary
)
SELECT r.r_name,
       r.total_freight_revenue,
       ar.avg_revenue,
       CASE 
           WHEN r.total_freight_revenue > ar.avg_revenue THEN 'Above Average'
           WHEN r.total_freight_revenue < ar.avg_revenue THEN 'Below Average'
           ELSE 'Average'
       END AS revenue_status
FROM RankedRegions r
JOIN AverageRevenue ar ON 1=1
WHERE r.revenue_rank <= 10;