WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_partkey
),
SalesInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(ts.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(ts.total_sales, 0) = 0 THEN 'No Sales'
            ELSE 'Has Sales'
        END AS sales_status
    FROM 
        part p
    LEFT JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
),
SupplierPart AS (
    SELECT DISTINCT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    si.p_partkey,
    si.p_name,
    si.total_sales,
    si.sales_status,
    sp.s_suppkey,
    sp.s_name,
    sp.s_acctbal
FROM 
    SalesInfo si
LEFT JOIN 
    SupplierPart sp ON si.p_partkey = sp.ps_partkey
WHERE 
    (si.sales_status = 'No Sales' OR sp.s_acctbal > 1000.00)
ORDER BY 
    si.total_sales DESC, si.p_partkey
LIMIT 100 OFFSET 0;
