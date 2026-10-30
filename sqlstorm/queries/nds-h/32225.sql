
WITH  regional_orders AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        n.n_nationkey, n.n_name
    UNION ALL
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(CASE WHEN o.o_orderkey IS NOT NULL THEN 1 ELSE 0 END) AS order_count,
        SUM(COALESCE(o.o_totalprice, 0)) AS total_revenue
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
ranked_orders AS (
    SELECT 
        region.n_name AS region_name,
        region.order_count,
        region.total_revenue,
        RANK() OVER (ORDER BY region.total_revenue DESC) AS revenue_rank
    FROM 
        regional_orders region
)
SELECT 
    ro.region_name,
    ro.order_count,
    ro.total_revenue,
    COALESCE(r2.region_name, 'No Region Match') AS alternative_region
FROM 
    ranked_orders ro
FULL OUTER JOIN 
    ranked_orders r2 ON ro.revenue_rank = r2.revenue_rank - 1
WHERE 
    ro.order_count > (SELECT AVG(order_count) FROM ranked_orders WHERE revenue_rank <= 5)
ORDER BY 
    ro.total_revenue DESC, ro.order_count DESC;
