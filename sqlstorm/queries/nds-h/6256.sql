
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        COUNT(o.o_orderkey) AS OrderCount
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS OrderRevenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        o.o_orderkey, 
        o.o_orderdate
)
SELECT 
    r.s_name AS SupplierName,
    r.TotalSupplyCost,
    c.c_name AS CustomerName,
    c.OrderCount,
    o.OrderRevenue
FROM 
    RankedSuppliers r
JOIN 
    HighValueCustomers c ON r.s_suppkey = c.c_custkey
JOIN 
    RecentOrders o ON o.o_orderkey = c.c_custkey
WHERE 
    r.SupplierRank <= 10
ORDER BY 
    r.TotalSupplyCost DESC, 
    c.OrderCount DESC;
