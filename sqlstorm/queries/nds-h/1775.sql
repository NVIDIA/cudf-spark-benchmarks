WITH regional_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        r.r_regionkey, r.r_name
),
top_sales AS (
    SELECT 
        region_name,
        total_sales,
        order_count
    FROM 
        regional_sales
    WHERE 
        sales_rank <= 5
)

SELECT 
    ts.region_name,
    ts.total_sales,
    ts.order_count,
    COALESCE((SELECT AVG(ts2.total_sales) FROM top_sales ts2 WHERE ts2.region_name <> ts.region_name), 0) AS avg_other_sales,
    CASE 
        WHEN ts.total_sales > (SELECT AVG(total_sales) FROM top_sales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_comparison
FROM 
    top_sales ts
ORDER BY 
    ts.total_sales DESC;

