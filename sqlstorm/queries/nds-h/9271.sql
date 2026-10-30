WITH regional_summary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        COUNT(o.o_orderkey) AS orders_count
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
        r.r_regionkey, r.r_name
),
top_regions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        total_sales,
        customer_count,
        orders_count,
        RANK() OVER (ORDER BY total_sales DESC) as sales_rank
    FROM 
        regional_summary r
)
SELECT 
    r.r_regionkey,
    r.r_name,
    r.total_sales,
    r.customer_count,
    r.orders_count
FROM 
    top_regions r
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.total_sales DESC;
