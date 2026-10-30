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
),
TopSuppliers AS (
    SELECT 
        s.s_name, 
        s.TotalSupplyCost,
        RANK() OVER (ORDER BY s.TotalSupplyCost DESC) AS SupplierRank
    FROM 
        RankedSuppliers s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        AVG(o.o_totalprice) AS AvgOrderValue,
        COUNT(o.o_orderkey) AS OrderCount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_name,
        c.AvgOrderValue,
        c.OrderCount,
        RANK() OVER (ORDER BY c.AvgOrderValue DESC) AS CustomerRank
    FROM 
        CustomerOrders c
    WHERE 
        c.OrderCount > 10
)
SELECT 
    t.s_name AS SupplierName,
    t.TotalSupplyCost AS SupplierTotalCost,
    h.c_name AS CustomerName,
    h.AvgOrderValue AS CustomerAvgOrderValue,
    h.OrderCount AS CustomerTotalOrders
FROM 
    TopSuppliers t
JOIN 
    HighValueCustomers h ON t.SupplierRank = h.CustomerRank
WHERE 
    t.SupplierRank <= 10
ORDER BY 
    t.TotalSupplyCost DESC, h.AvgOrderValue DESC;
