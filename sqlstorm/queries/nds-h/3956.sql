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
    WHERE o.o_orderstatus = 'O' 
    GROUP BY s.s_suppkey, s.s_name
),
NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ss.total_sales) AS nation_sales,
        COUNT(DISTINCT ss.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY n.n_nationkey, n.n_name
),
TotalSales AS (
    SELECT 
        SUM(total_sales) AS grand_total_sales,
        COUNT(s_suppkey) AS total_suppliers
    FROM SupplierSales
)
SELECT 
    n.n_name,
    COALESCE(ns.nation_sales, 0) AS nation_sales,
    COALESCE(ns.supplier_count, 0) AS supplier_count,
    (ns.nation_sales / NULLIF(ts.grand_total_sales, 0)) * 100 AS nation_sales_percentage
FROM nation n
LEFT JOIN NationSales ns ON n.n_nationkey = ns.n_nationkey
CROSS JOIN TotalSales ts
ORDER BY nation_sales_percentage DESC;
