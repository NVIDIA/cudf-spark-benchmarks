WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
), RankedSales AS (
    SELECT 
        nation_name, 
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    rs.nation_name, 
    rs.total_sales, 
    rs.order_count,
    CASE 
        WHEN rs.sales_rank <= 5 THEN 'Top 5'
        WHEN rs.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS sales_category
FROM 
    RankedSales rs
LEFT JOIN part p ON rs.nation_name = p.p_brand
WHERE 
    rs.total_sales IS NOT NULL 
    AND p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2 
        WHERE p2.p_size > 10
    )
UNION ALL 
SELECT 
    'Average' AS nation_name,
    AVG(total_sales) AS total_sales,
    SUM(order_count) AS order_count,
    'Aggregate' AS sales_category
FROM 
    RankedSales
WHERE 
    order_count > 0
ORDER BY 
    total_sales DESC;
