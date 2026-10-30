WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01'
), 
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        s.s_suppkey
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.TotalSales,
        ss.OrderCount,
        RANK() OVER (ORDER BY ss.TotalSales DESC) AS SalesRank
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    r.r_name AS RegionName,
    t.s_suppkey,
    t.s_name,
    t.TotalSales,
    t.OrderCount,
    ro.o_orderdate,
    ro.o_totalprice
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    TopSuppliers t ON s.s_suppkey = t.s_suppkey
LEFT JOIN 
    RankedOrders ro ON t.s_suppkey = ro.o_orderkey AND t.OrderCount > 5
WHERE 
    t.SalesRank <= 10
ORDER BY 
    r.r_name, t.TotalSales DESC;