
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        JOIN customer c ON o.o_custkey = c.c_custkey
        JOIN supplier s ON l.l_suppkey = s.s_suppkey
        JOIN nation n ON s.s_nationkey = n.n_nationkey
        JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
        AND c.c_acctbal > 1000
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT
        region_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
ProductSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_product_sales
    FROM 
        lineitem l
        JOIN part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.region_name,
    COALESCE(ps.total_product_sales, 0) AS product_sales,
    CASE 
        WHEN ps.total_product_sales IS NULL THEN 'No Sales'
        ELSE 'Sales present'
    END AS sales_status,
    r.total_sales
FROM 
    TopRegions r
LEFT OUTER JOIN ProductSales ps ON r.region_name = (
    SELECT n.n_name
    FROM nation n 
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_suppkey IN (SELECT DISTINCT l.l_suppkey FROM lineitem l WHERE l.l_shipdate IS NOT NULL)
    LIMIT 1
)
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.total_sales DESC;
