
WITH  regional_sales AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    GROUP BY 
        r.r_regionkey, r.r_name

    UNION ALL

    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    WHERE 
        l.l_shipdate < DATE '1998-10-01' - INTERVAL '1 year' AND
        l.l_discount BETWEEN 0.05 AND 0.10
    GROUP BY 
        r.r_regionkey, r.r_name
),
total_sales_summary AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) DESC) AS revenue_rank
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
        r.r_name
)
SELECT 
    r.r_name AS region_name,
    COALESCE(s.order_count, 0) AS total_orders,
    COALESCE(s.total_revenue, 0) AS total_revenue,
    SUM(COALESCE(s.total_revenue, 0)) OVER (PARTITION BY r.r_regionkey ORDER BY COALESCE(s.total_revenue, 0) DESC) AS cumulative_revenue
FROM 
    region r
LEFT JOIN 
    total_sales_summary s ON r.r_name = s.r_name
WHERE 
    s.order_count > 0
ORDER BY 
    cumulative_revenue DESC;
