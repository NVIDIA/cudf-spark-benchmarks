WITH  region_sales AS (
    SELECT 
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
        r.r_name
),
sales_ranks AS (
    SELECT 
        r_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        region_sales
)
SELECT 
    sr.r_name,
    COALESCE(sr.total_sales, 0) AS total_sales,
    CASE 
        WHEN sr.total_sales IS NULL THEN 'No sales'
        ELSE 'Sales recorded'
    END AS sales_status,
    (SELECT COUNT(*) FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_quantity > 10)) AS high_quantity_order_count
FROM 
    sales_ranks sr
LEFT JOIN 
    nation n ON sr.r_name = n.n_name
WHERE 
    sr.sales_rank <= 5 
    OR sr.total_sales IS NULL
ORDER BY 
    sr.sales_rank;
