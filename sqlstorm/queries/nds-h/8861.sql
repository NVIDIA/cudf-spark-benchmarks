
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        rs.region_name
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rn <= 5
),
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    GROUP BY 
        l.l_suppkey
),
SupplierSales AS (
    SELECT 
        ts.s_suppkey,
        ts.s_name,
        ts.region_name,
        COALESCE(ss.total_sales, 0) AS total_sales
    FROM 
        TopSuppliers ts
    LEFT JOIN 
        TotalSales ss ON ts.s_suppkey = ss.l_suppkey
)
SELECT 
    s.region_name,
    COUNT(*) AS supplier_count,
    SUM(s.total_sales) AS total_sales,
    AVG(s.total_sales) AS avg_sales,
    MIN(s.total_sales) AS min_sales,
    MAX(s.total_sales) AS max_sales
FROM 
    SupplierSales s
GROUP BY 
    s.region_name
ORDER BY 
    total_sales DESC;
