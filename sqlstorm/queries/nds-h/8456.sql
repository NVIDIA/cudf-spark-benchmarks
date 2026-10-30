WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
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
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
        AND l.l_shipmode = 'AIR'
    GROUP BY 
        s.s_suppkey, s.s_name
), TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        so.TotalRevenue,
        so.OrderCount,
        RANK() OVER (ORDER BY so.TotalRevenue DESC) AS RevenueRank
    FROM 
        SupplierOrders so
    JOIN 
        supplier s ON so.s_suppkey = s.s_suppkey
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.TotalRevenue,
    t.OrderCount,
    t.RevenueRank,
    c.c_mktsegment
FROM 
    TopSuppliers t
JOIN 
    customer c ON t.s_suppkey = c.c_nationkey
WHERE 
    t.RevenueRank <= 10
ORDER BY 
    t.TotalRevenue DESC;