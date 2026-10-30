WITH LatestOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_custkey,
        CONCAT(c.c_name, ' from ', c.c_address) AS CustomerInfo
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate = (SELECT MAX(o2.o_orderdate) FROM orders o2)
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(ls.TotalLines, 0) AS TotalLines,
    COALESCE(ps.TotalSupplyCost, 0) AS TotalSupplyCost,
    CASE 
        WHEN ps.TotalSupplyCost IS NULL THEN 'No suppliers available'
        ELSE 'Available'
    END AS SupplyStatus
FROM 
    part p
LEFT JOIN (
    SELECT 
        l.l_partkey,
        COUNT(*) AS TotalLines
    FROM 
        lineitem l
    JOIN 
        LatestOrders lo ON l.l_orderkey = lo.o_orderkey
    GROUP BY 
        l.l_partkey
) ls ON p.p_partkey = ls.l_partkey
LEFT JOIN PartSuppliers ps ON p.p_partkey = ps.ps_partkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_container = 'BOX')
    AND p.p_size BETWEEN 5 AND 20
ORDER BY 
    p.p_partkey DESC;
