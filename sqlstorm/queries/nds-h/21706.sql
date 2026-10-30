WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
        INNER JOIN supplier s ON n.n_nationkey = s.s_nationkey
        INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        INNER JOIN part p ON ps.ps_partkey = p.p_partkey
        INNER JOIN lineitem l ON p.p_partkey = l.l_partkey
        INNER JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate >= '1997-01-01'
    GROUP BY 
        n.n_name
), TopRegions AS (
    SELECT 
        nation_name,
        total_sales,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
), SupplierStats AS (
    SELECT 
        s.s_name,
        AVG(s.s_acctbal) AS avg_acctbal,
        COUNT(s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_name
), CombinedData AS (
    SELECT 
        tr.nation_name,
        tr.total_sales,
        ts.avg_acctbal,
        ts.supplier_count
    FROM 
        TopRegions tr
        LEFT JOIN SupplierStats ts ON tr.nation_name = ts.s_name
)
SELECT 
    cd.nation_name,
    COALESCE(cd.total_sales, 0) AS total_sales,
    COALESCE(cd.avg_acctbal, 0.00) AS avg_acctbal,
    cd.supplier_count,
    CASE 
        WHEN cd.total_sales > 1000000 THEN 'High'
        WHEN cd.total_sales BETWEEN 500000 AND 1000000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    CombinedData cd
WHERE 
    cd.supplier_count IS NULL 
    OR cd.avg_acctbal > (
        SELECT AVG(avg_acctbal)
        FROM SupplierStats
        WHERE supplier_count > 10
    )
ORDER BY 
    sales_category DESC,
    cd.total_sales ASC
LIMIT 100
OFFSET 50;