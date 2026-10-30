
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    p.p_name AS ProductName,
    COUNT(DISTINCT rs.s_suppkey) AS SupplierCount,
    SUM(CASE WHEN rs.rank = 1 THEN rs.ps_supplycost ELSE 0 END) AS CheapestSupplyCost
FROM 
    part p
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.p_partkey
GROUP BY 
    p.p_name
ORDER BY 
    SupplierCount DESC, CheapestSupplyCost ASC;
