WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS TotalSuppliedParts,
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        SUM(l.l_quantity) AS TotalQuantity,
        SUM(l.l_tax) AS TotalTax
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)

SELECT 
    r.o_orderkey,
    r.o_totalprice,
    r.o_orderdate,
    r.o_orderpriority,
    s.TotalSuppliedParts,
    s.TotalSupplyCost,
    l.TotalSales,
    l.TotalQuantity,
    l.TotalTax
FROM 
    RankedOrders r
JOIN 
    SupplierStats s ON r.o_orderkey = s.s_suppkey
JOIN 
    LineItemStats l ON r.o_orderkey = l.l_orderkey
WHERE 
    r.OrderRank <= 10
ORDER BY 
    r.o_orderdate DESC;