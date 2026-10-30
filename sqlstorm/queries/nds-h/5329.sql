WITH regional_summary AS (
    SELECT 
        r.r_name AS region_name,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice * (1 - l.l_discount) END) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
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
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        r.r_name
),
overall_summary AS (
    SELECT 
        region_name,
        total_revenue,
        total_customers,
        total_orders,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        regional_summary
)
SELECT 
    region_name,
    total_revenue,
    total_customers,
    total_orders,
    revenue_rank,
    ROUND(total_revenue / NULLIF(total_orders, 0), 2) AS avg_revenue_per_order
FROM 
    overall_summary
WHERE 
    total_orders > 0
ORDER BY 
    revenue_rank;
