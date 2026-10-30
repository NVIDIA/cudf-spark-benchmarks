WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(ss.total_sales, 0) AS total_sales
    FROM supplier s
    LEFT JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
SalesRank AS (
    SELECT 
        hvs.s_suppkey,
        hvs.s_name,
        hvs.total_sales,
        RANK() OVER (ORDER BY hvs.total_sales DESC) AS sales_rank
    FROM HighValueSuppliers hvs
)
SELECT 
    r.r_name,
    COUNT(DISTINCT sr.s_suppkey) AS supplier_count,
    SUM(sr.total_sales) AS total_sales_by_region
FROM SalesRank sr
JOIN supplier s ON sr.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE sr.total_sales > 10000
GROUP BY r.r_name
ORDER BY total_sales_by_region DESC
LIMIT 5;