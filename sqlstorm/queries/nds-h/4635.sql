WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS UniquePartsSupplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalOrderValue,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS OrderRank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000.00
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS NumberOfNations,
    COALESCE(SUM(ss.TotalSupplyCost), 0) AS TotalSupplyCostByRegion,
    COALESCE(SUM(co.TotalOrderValue), 0) AS TotalOrderValueByRegion
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    CustomerOrders co ON s.s_nationkey = co.c_custkey
WHERE 
    r.r_name IS NOT NULL AND 
    EXISTS (SELECT 1 FROM partsupp ps WHERE ps.ps_supplycost > 10) 
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name DESC
LIMIT 10;
