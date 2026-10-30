WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F'
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
    JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.TotalSales IS NOT NULL
)
SELECT 
    r.r_name AS RegionName,
    t.s_name AS SupplierName,
    t.TotalSales,
    t.OrderCount,
    o.o_orderdate,
    o.o_totalprice
FROM 
    TopSuppliers t
LEFT JOIN nation n ON t.s_suppkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN RankedOrders o ON t.OrderCount > 5
WHERE 
    t.SalesRank <= 10
ORDER BY 
    r.r_name, t.TotalSales DESC, o.o_orderdate;