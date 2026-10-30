
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplyRank,
        n.n_name AS NationName
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), CustomerOrderSummary AS (
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
)
SELECT 
    rs.NationName,
    rs.s_name AS SupplierName,
    c.c_name AS CustomerName,
    cos.TotalOrders,
    cos.TotalSpent,
    rs.TotalSupplyCost
FROM 
    RankedSuppliers rs
JOIN 
    nation ro ON rs.NationName = ro.n_name
JOIN 
    customer c ON c.c_nationkey = ro.n_nationkey
JOIN 
    CustomerOrderSummary cos ON c.c_custkey = cos.c_custkey
WHERE 
    rs.SupplyRank <= 5
ORDER BY 
    rs.NationName, cos.TotalSpent DESC;
