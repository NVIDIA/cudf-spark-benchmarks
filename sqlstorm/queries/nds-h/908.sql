
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
        SUM(ss.total_sales) AS total_nation_sales,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY n.n_nationkey, n.n_name
),
RankedSales AS (
    SELECT 
        n.n_name,
        ns.total_nation_sales,
        ns.supplier_count,
        RANK() OVER (ORDER BY ns.total_nation_sales DESC) AS sales_rank
    FROM nation n
    JOIN NationSales ns ON n.n_nationkey = ns.n_nationkey
)
SELECT 
    r.n_name,
    COALESCE(ns.total_nation_sales, 0) AS total_sales,
    COALESCE(ns.supplier_count, 0) AS supplier_count,
    CASE 
        WHEN ns.supplier_count > 0 THEN ROUND(ns.total_nation_sales / ns.supplier_count, 2)
        ELSE NULL
    END AS avg_sales_per_supplier
FROM nation r
LEFT JOIN NationSales ns ON r.n_nationkey = ns.n_nationkey
WHERE r.n_name IS NOT NULL
ORDER BY COALESCE(ns.total_nation_sales, 0) DESC, r.n_name;
