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
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        l.l_suppkey
)
SELECT 
    rs.s_suppkey,
    rs.s_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    rs.s_acctbal,
    CASE 
        WHEN ts.total_sales IS NULL THEN 'No Sales'
        WHEN ts.total_sales >= rs.s_acctbal THEN 'Profitable Supplier'
        ELSE 'Check Supplier'
    END AS supplier_status
FROM 
    RankedSuppliers rs
LEFT JOIN 
    TotalSales ts ON rs.s_suppkey = ts.l_suppkey
WHERE 
    rs.rank = 1 AND 
    rs.s_acctbal IS NOT NULL
ORDER BY 
    total_sales DESC, 
    rs.s_name;