
WITH  region_sales AS (
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
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 0
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
ranked_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.order_count,
        c.avg_order_value,
        RANK() OVER (ORDER BY c.avg_order_value DESC) AS rank
    FROM 
        customer_orders c
)
SELECT 
    r.r_name,
    r.total_sales,
    rc.c_name,
    rc.order_count,
    rc.avg_order_value
FROM 
    region_sales r
FULL OUTER JOIN 
    ranked_customers rc ON r.r_name LIKE '%' || rc.c_name || '%'
WHERE 
    r.total_sales IS NOT NULL OR rc.avg_order_value IS NOT NULL
ORDER BY 
    r.total_sales DESC NULLS LAST, rc.avg_order_value DESC NULLS LAST;
