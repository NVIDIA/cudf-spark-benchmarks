WITH regional_summary AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_f_revenue,
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
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
    GROUP BY 
        r.r_name, n.n_name
),
average_order_value AS (
    SELECT 
        r.region_name,
        AVG(total_f_revenue / NULLIF(total_orders, 0)) AS avg_order_value
    FROM 
        regional_summary r
    GROUP BY 
        r.region_name
)
SELECT 
    r.region_name, 
    r.nation_name,
    r.total_f_revenue,
    r.total_orders,
    a.avg_order_value
FROM 
    regional_summary r
JOIN 
    average_order_value a ON r.region_name = a.region_name
ORDER BY 
    r.total_f_revenue DESC, 
    a.avg_order_value DESC;