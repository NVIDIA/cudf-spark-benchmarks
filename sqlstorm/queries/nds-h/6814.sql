WITH RegionOrders AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue,
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
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        region_name, 
        total_orders, 
        total_revenue, 
        avg_order_value,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RegionOrders
)
SELECT 
    region_name,
    total_orders,
    total_revenue,
    avg_order_value
FROM 
    TopRegions
WHERE 
    revenue_rank <= 5
ORDER BY 
    total_revenue DESC;
