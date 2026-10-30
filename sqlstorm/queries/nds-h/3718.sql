WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        l.l_suppkey
),
SuppliersWithSales AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        COALESCE(ts.total_revenue, 0) AS total_revenue
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        TotalSales ts ON rs.s_suppkey = ts.l_suppkey
    WHERE 
        rs.rank <= 5
)
SELECT 
    sws.s_suppkey,
    sws.s_name,
    sws.s_acctbal,
    sws.total_revenue,
    CASE 
        WHEN sws.total_revenue = 0 THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    SuppliersWithSales sws
ORDER BY 
    sws.total_revenue DESC, 
    sws.s_name ASC
LIMIT 10;