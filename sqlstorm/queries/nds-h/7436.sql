
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighCostSuppliers AS (
    SELECT 
        s.Rank,
        s.s_suppkey,
        s.s_name,
        n.n_name AS NationName,
        s.TotalSupplyCost,
        s.s_nationkey
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.Rank = 1
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalReport AS (
    SELECT 
        hcs.NationName,
        hcs.s_name AS SupplierName,
        co.c_name AS CustomerName,
        co.TotalOrders,
        co.TotalSpent,
        hcs.TotalSupplyCost
    FROM 
        HighCostSuppliers hcs
    JOIN 
        CustomerOrders co ON hcs.s_nationkey = co.c_custkey
)
SELECT 
    NationName,
    SupplierName,
    CustomerName,
    TotalOrders,
    TotalSpent,
    TotalSupplyCost
FROM 
    FinalReport
ORDER BY 
    NationName, TotalSupplyCost DESC, TotalSpent DESC;
