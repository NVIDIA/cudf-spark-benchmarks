WITH SupplierAgg AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_nationkey,
        COUNT(o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    r.r_name,
    COALESCE(SA.TotalSupplyCost, 0) AS TotalSupplyCost,
    COALESCE(CO.TotalOrders, 0) AS TotalOrders,
    COALESCE(CO.TotalSpent, 0) AS TotalSpent,
    (COALESCE(SA.TotalSupplyCost, 0) / NULLIF(COALESCE(CO.TotalOrders, 0), 0)) AS AvgCostPerOrder
FROM 
    region r
LEFT JOIN 
    SupplierAgg SA ON r.r_regionkey = SA.s_nationkey
LEFT JOIN 
    CustomerOrders CO ON r.r_regionkey = CO.c_nationkey
WHERE 
    r.r_name IN ('ASIA', 'EUROPE')
ORDER BY 
    AvgCostPerOrder DESC;
