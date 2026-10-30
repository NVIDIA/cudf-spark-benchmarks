WITH RevenueData AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        nation n
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
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        n.n_name
),
TieredRevenue AS (
    SELECT 
        nation_name,
        total_revenue,
        total_orders,
        CASE 
            WHEN total_revenue >= 1000000 THEN 'High'
            WHEN total_revenue >= 500000 THEN 'Medium'
            ELSE 'Low'
        END AS revenue_tier
    FROM 
        RevenueData
)
SELECT 
    revenue_tier,
    COUNT(nation_name) AS nation_count,
    AVG(total_revenue) AS avg_revenue,
    SUM(total_orders) AS total_orders_aggregated
FROM 
    TieredRevenue
GROUP BY 
    revenue_tier
ORDER BY 
    revenue_tier DESC;