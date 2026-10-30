WITH region_summary AS (
    SELECT 
        r.r_name AS region_name,
        SUM(o.o_totalprice) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
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
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        r.r_name
),
ranked_regions AS (
    SELECT 
        region_name,
        total_revenue,
        total_orders,
        avg_order_value,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        region_summary
)

SELECT 
    rr.region_name,
    rr.total_revenue,
    rr.total_orders,
    rr.avg_order_value
FROM 
    ranked_regions rr
WHERE 
    rr.revenue_rank <= 10
ORDER BY 
    rr.revenue_rank;