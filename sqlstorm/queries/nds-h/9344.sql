WITH regional_sales AS (
    SELECT 
        r.r_name AS region,
        sum(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
top_regions AS (
    SELECT 
        region,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) as sales_rank
    FROM 
        regional_sales
)
SELECT 
    tr.region,
    tr.total_sales
FROM 
    top_regions tr
WHERE 
    tr.sales_rank <= 5
ORDER BY 
    tr.total_sales DESC;
