
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS RankInNation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerTotalPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalPurchases
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS RegionName,
    ns.s_name AS SupplierName,
    cp.c_name AS CustomerName,
    cp.TotalPurchases,
    ns.TotalSupplyCost
FROM 
    RankedSuppliers ns
JOIN 
    nation n ON ns.s_nationkey = n.n_nationkey
JOIN 
    CustomerTotalPurchases cp ON ns.TotalSupplyCost > cp.TotalPurchases
WHERE 
    ns.RankInNation = 1
ORDER BY 
    RegionName, ns.TotalSupplyCost DESC;
