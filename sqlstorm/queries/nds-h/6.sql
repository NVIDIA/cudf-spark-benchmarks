WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS ranking
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
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
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        l.l_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    rs.s_name,
    rs.ranking,
    CASE 
        WHEN rs.ranking <= 5 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS supplier_tier
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
LEFT JOIN 
    TotalSales ts ON rs.s_suppkey = ts.l_suppkey
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
    AND (ts.total_sales IS NULL OR ts.total_sales > 10000)
ORDER BY 
    total_sales DESC, 
    p.p_partkey;