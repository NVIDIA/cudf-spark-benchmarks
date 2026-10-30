WITH RankedSales AS (
    SELECT 
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY l_partkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS sales_rank
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1996-01-01' AND l_shipdate < DATE '1997-01-01'
    GROUP BY 
        l_partkey
), 
FilterSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        s_acctbal,
        n_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)

SELECT 
    p.p_name,
    p.p_container,
    rs.total_sales,
    fs.s_name,
    fs.n_name,
    COALESCE(fs.s_acctbal - 100.00, 0) AS adjusted_acctbal
FROM 
    part p
LEFT JOIN 
    RankedSales rs ON p.p_partkey = rs.l_partkey AND rs.sales_rank = 1
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    FilterSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
WHERE 
    p.p_size = (SELECT MAX(p2.p_size) FROM part p2 WHERE p2.p_type = p.p_type)
    AND (fs.s_acctbal IS NOT NULL OR rs.total_sales IS NOT NULL)
ORDER BY 
    total_sales DESC NULLS LAST
LIMIT 10;