WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
),
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        l.l_suppkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        COALESCE(ts.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(ts.total_sales, 0) > 10000 THEN 'High'
            WHEN COALESCE(ts.total_sales, 0) BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low' 
        END AS sales_category
    FROM 
        supplier s
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        TotalSales ts ON s.s_suppkey = ts.l_suppkey
),
FinalReport AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.nation_name,
        sd.s_acctbal,
        sd.total_sales,
        sd.sales_category,
        rs.supplier_rank
    FROM 
        SupplierDetails sd
    JOIN 
        RankedSuppliers rs ON sd.s_suppkey = rs.s_suppkey
    WHERE 
        sd.sales_category = 'High' 
        OR rs.supplier_rank <= 5
    ORDER BY 
        sd.total_sales DESC, rs.supplier_rank
)
SELECT 
    fr.s_suppkey,
    fr.s_name,
    fr.nation_name,
    fr.s_acctbal,
    fr.total_sales,
    fr.sales_category
FROM 
    FinalReport fr
WHERE 
    fr.total_sales > (
        SELECT AVG(total_sales) FROM TotalSales
    )
    AND fr.s_acctbal IS NOT NULL
UNION ALL
SELECT 
    NULL AS s_suppkey,
    'TOTAL' AS s_name,
    NULL AS nation_name,
    NULL AS s_acctbal,
    SUM(total_sales) AS total_sales,
    'Sum' AS sales_category
FROM 
    FinalReport;