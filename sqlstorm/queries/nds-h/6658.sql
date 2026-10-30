
WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS TotalOrders,
        c.c_nationkey
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
)
SELECT 
    r.r_name AS Region,
    ns.n_name AS Nation,
    COUNT(DISTINCT s.s_suppkey) AS SupplierCount,
    COUNT(DISTINCT co.c_custkey) AS CustomerCount,
    SUM(co.TotalOrders) AS TotalRevenue
FROM 
    region r
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    RankedSupplier s ON ns.n_nationkey = s.s_nationkey AND s.Rank <= 5
LEFT JOIN 
    CustomerOrders co ON ns.n_nationkey = co.c_nationkey
WHERE 
    r.r_name LIKE 'A%'
GROUP BY 
    r.r_name, ns.n_name
ORDER BY 
    TotalRevenue DESC;
