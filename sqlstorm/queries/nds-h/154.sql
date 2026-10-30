WITH  SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.TotalSales,
        RANK() OVER (ORDER BY s.TotalSales DESC) AS SalesRank
    FROM 
        SupplierSales s
)
SELECT 
    r.r_name,
    n.n_name,
    COUNT(DISTINCT c.c_custkey) as TotalCustomers,
    COALESCE(SUM(p.p_retailprice), 0) AS TotalRetailPrice,
    COALESCE(AVG(rs.TotalSales), 0) AS AverageSupplierSales
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    customer c ON s.s_suppkey = c.c_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_name = rs.s_name
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5 AND
    COALESCE(SUM(p.p_retailprice), 0) > 1000
ORDER BY 
    TotalRetailPrice DESC
LIMIT 10;