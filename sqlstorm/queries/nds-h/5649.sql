WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name IN ('FRANCE', 'GERMANY', 'USA')
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
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        l.l_suppkey
),
AverageSales AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        ts.total_sales,
        AVG(ts.total_sales) OVER (PARTITION BY rs.s_suppkey) AS avg_sales
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        TotalSales ts ON rs.s_suppkey = ts.l_suppkey
)
SELECT 
    a.s_name,
    a.total_sales,
    a.avg_sales,
    a.total_sales - a.avg_sales AS sales_difference
FROM 
    AverageSales a
WHERE 
    a.total_sales > a.avg_sales
ORDER BY 
    sales_difference DESC
LIMIT 10;