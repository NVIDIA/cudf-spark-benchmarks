WITH RegionalSales AS (
    SELECT 
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
), DiscountedSales AS (
    SELECT 
        region,
        total_sales,
        CASE 
            WHEN total_sales > 1000000 THEN 'High'
            WHEN total_sales BETWEEN 500000 AND 1000000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        RegionalSales
), FinalReport AS (
    SELECT 
        region,
        total_sales,
        sales_category,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        DiscountedSales
)
SELECT 
    region,
    total_sales,
    sales_category,
    sales_rank
FROM 
    FinalReport
WHERE 
    sales_category = 'High'
ORDER BY 
    sales_rank;
