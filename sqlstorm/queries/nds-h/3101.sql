WITH RegionSales AS (
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        r_name,
        total_revenue,
        total_orders,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RegionSales
)
SELECT 
    tr.r_name,
    COALESCE(tr.total_revenue, 0) AS revenue,
    COALESCE(tr.total_orders, 0) AS orders,
    CASE 
        WHEN tr.revenue_rank = 1 THEN 'Top Region'
        WHEN tr.revenue_rank <= 5 THEN 'Top 5 Region'
        ELSE 'Other Region'
    END AS region_category
FROM 
    TopRegions tr
LEFT JOIN 
    region r ON tr.r_name = r.r_name
WHERE 
    r.r_comment IS NULL OR r.r_comment NOT LIKE '%test%'
ORDER BY 
    tr.revenue_rank;