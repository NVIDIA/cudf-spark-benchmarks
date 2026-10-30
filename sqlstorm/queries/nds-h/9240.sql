
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        TotalSupplyCost DESC
    LIMIT 10
), CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS TotalOrders, 
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    r.r_name AS Region,
    n.n_name AS Nation,
    cs.c_name AS Customer,
    rs.s_name AS Supplier,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS Revenue,
    COUNT(DISTINCT o.o_orderkey) AS OrderCount
FROM 
    lineitem li
JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
JOIN 
    customer cs ON o.o_custkey = cs.c_custkey
JOIN 
    supplier rs ON li.l_suppkey = rs.s_suppkey
JOIN 
    partsupp ps ON li.l_partkey = ps.ps_partkey AND rs.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON cs.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    li.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    r.r_name, n.n_name, cs.c_name, rs.s_name
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
ORDER BY 
    Revenue DESC;
