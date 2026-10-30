WITH SupplierOrderSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY s.s_suppkey, s.s_name
),

RegionRevenue AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(sos.total_revenue) AS total_region_revenue
    FROM SupplierOrderSummary sos
    JOIN supplier s ON sos.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_regionkey, r.r_name
)

SELECT 
    rr.r_name,
    rr.total_region_revenue,
    RANK() OVER (ORDER BY rr.total_region_revenue DESC) AS revenue_rank,
    CASE 
        WHEN rr.total_region_revenue IS NULL THEN 'No Revenue'
        ELSE 'Revenue Generated'
    END AS revenue_status
FROM RegionRevenue rr
WHERE rr.total_region_revenue > (SELECT AVG(total_region_revenue) FROM RegionRevenue)
UNION ALL
SELECT 
    'Total' AS r_name,
    SUM(total_region_revenue) AS total_region_revenue,
    NULL AS revenue_rank,
    'Total Revenue' AS revenue_status
FROM RegionRevenue
ORDER BY total_region_revenue DESC NULLS LAST;