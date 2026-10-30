
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT o.o_custkey) AS UniqueCustomers,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS RevenueRank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopOrders AS (
    SELECT o_orderkey, TotalRevenue, UniqueCustomers
    FROM RankedOrders
    WHERE RevenueRank <= 10
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    o.o_orderkey,
    o.TotalRevenue,
    o.UniqueCustomers,
    sp.TotalSupplyCost
FROM 
    TopOrders o
JOIN 
    SupplierParts sp ON o.o_orderkey = sp.ps_partkey
JOIN 
    part p ON sp.ps_partkey = p.p_partkey
WHERE 
    p.p_type LIKE '%metal%'
ORDER BY 
    o.TotalRevenue DESC, sp.TotalSupplyCost ASC;
