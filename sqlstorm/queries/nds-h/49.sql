WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        l.l_suppkey
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(ts.total_sales, 0) AS total_sales,
        r.r_name
    FROM 
        supplier s
    LEFT JOIN 
        TotalSales ts ON s.s_suppkey = ts.l_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2) 
),
FinalReport AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_sales,
        ss.r_name,
        CASE 
            WHEN ss.total_sales > 100000 THEN 'High'
            WHEN ss.total_sales BETWEEN 50000 AND 100000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_status
    FROM 
        SupplierSales ss
    WHERE 
        ss.total_sales IS NOT NULL
)
SELECT 
    fr.s_suppkey,
    fr.s_name,
    fr.total_sales,
    fr.r_name,
    fr.sales_status
FROM 
    FinalReport fr
WHERE 
    fr.sales_status = 'High'
ORDER BY 
    fr.total_sales DESC
LIMIT 10 OFFSET 0;