
WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
),
MaxSales AS (
    SELECT 
        nation_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
OrderedNations AS (
    SELECT 
        nation_name,
        MAX(total_sales) AS max_sales
    FROM 
        MaxSales
    GROUP BY 
        nation_name
    HAVING 
        MAX(total_sales) IS NOT NULL
)
SELECT 
    r.r_name,
    COALESCE(m.total_sales, 0) AS total_sales,
    COALESCE(m.order_count, 0) AS order_count,
    CASE 
        WHEN m.sales_rank = 1 THEN 'Top Seller'
        WHEN m.sales_rank IS NULL THEN 'No Sales'
        ELSE 'Regular Seller' 
    END AS sales_category
FROM 
    region r
LEFT JOIN 
    (SELECT 
        rs.nation_name,
        rs.total_sales,
        rs.order_count,
        ms.sales_rank
    FROM 
        RegionalSales rs
    INNER JOIN 
        MaxSales ms ON rs.nation_name = ms.nation_name) m ON r.r_name = m.nation_name
ORDER BY 
    total_sales DESC,
    r.r_name ASC;
