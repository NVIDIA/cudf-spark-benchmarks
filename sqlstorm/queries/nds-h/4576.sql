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
        s.s_acctbal > 1000.00
),
TotalSales AS (
    SELECT 
        l.l_suppkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        l.l_suppkey
)
SELECT 
    p.p_name, 
    COALESCE(ts.total_price, 0) AS total_sales,
    rs.s_name AS supplier_name,
    rs.s_acctbal AS supplier_acctbal
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rank <= 3
LEFT JOIN 
    TotalSales ts ON rs.s_suppkey = ts.l_suppkey
WHERE 
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2 
        WHERE p2.p_type LIKE '%metal%' 
        AND p2.p_size IS NOT NULL
    )
AND 
    (p.p_comment LIKE '%fragile%' OR p.p_comment IS NULL)
ORDER BY 
    total_sales DESC, 
    p.p_name;
