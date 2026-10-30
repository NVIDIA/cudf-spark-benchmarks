
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 10000
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE('1997-01-01') AND l.l_shipdate < DATE('1998-01-01')
    GROUP BY 
        l.l_partkey
),
SupplierSales AS (
    SELECT 
        rs.s_suppkey,
        ts.l_partkey,
        ts.total_sales
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        partsupp ps ON ps.ps_suppkey = rs.s_suppkey
    LEFT JOIN 
        TotalSales ts ON ts.l_partkey = ps.ps_partkey
)
SELECT 
    n.n_name AS nation,
    COALESCE(SUM(ss.total_sales), 0) AS total_sales_by_supplier,
    COUNT(DISTINCT rs.s_suppkey) AS number_of_suppliers
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN 
    SupplierSales ss ON rs.s_suppkey = ss.s_suppkey
GROUP BY 
    n.n_name
ORDER BY 
    total_sales_by_supplier DESC;
