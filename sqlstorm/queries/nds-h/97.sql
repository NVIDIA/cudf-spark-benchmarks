WITH sales_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
        AND l.l_returnflag = 'N'
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name
),
highest_sales AS (
    SELECT 
        nation,
        MAX(total_sales) AS max_sales
    FROM 
        sales_summary
    GROUP BY 
        nation
)
SELECT 
    ss.c_name,
    ss.nation,
    ss.total_sales,
    ss.order_count,
    ss.sales_rank,
    CASE 
        WHEN hs.max_sales IS NOT NULL THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS sales_category
FROM 
    sales_summary ss
LEFT JOIN 
    highest_sales hs ON ss.nation = hs.nation AND ss.total_sales = hs.max_sales
WHERE 
    ss.sales_rank <= 5
ORDER BY 
    ss.nation, ss.total_sales DESC;