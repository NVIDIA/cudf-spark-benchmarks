
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        n.n_name AS nation_name,
        c.c_nationkey
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS RecentRank
    FROM 
        orders o
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    hvc.c_name,
    hvc.nation_name,
    COUNT(DISTINCT ro.o_orderkey) AS OrderCount,
    SUM(fli.Revenue) AS TotalRevenue,
    SUM(rs.TotalSupplyCost) AS TotalSupplierCost
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    RecentOrders ro ON hvc.c_custkey = ro.o_custkey AND ro.RecentRank <= 5
LEFT JOIN 
    FilteredLineItems fli ON ro.o_orderkey = fli.l_orderkey
JOIN 
    RankedSuppliers rs ON hvc.c_nationkey = rs.s_suppkey
WHERE 
    rs.Rank = 1
GROUP BY 
    hvc.c_name, hvc.nation_name
ORDER BY 
    TotalRevenue DESC;
