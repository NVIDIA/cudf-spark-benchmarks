WITH TotalSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1998-01-01' AND l.l_shipdate < DATE '1999-01-01'
    GROUP BY l.l_orderkey
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        SUM(ts.sales) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN TotalSales ts ON o.o_orderkey = ts.l_orderkey
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_custkey
),
SupplierCount AS (
    SELECT
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    cs.c_custkey,
    cs.total_sales,
    COALESCE(sc.supplier_count, 0) AS suppliers,
    CASE 
        WHEN cs.total_sales > 100000 THEN 'High'
        WHEN cs.total_sales BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM CustomerSales cs
LEFT JOIN (
    SELECT 
        l.l_partkey, 
        COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM lineitem l
    GROUP BY l.l_partkey
) sc ON cs.c_custkey = sc.l_partkey
ORDER BY cs.total_sales DESC
LIMIT 100;
