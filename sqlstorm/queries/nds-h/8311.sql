WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        SUM(l.l_quantity) AS TotalQuantity,
        COUNT(DISTINCT l.l_linenumber) AS TotalLineItems
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.o_orderpriority,
    ro.c_name,
    lis.TotalRevenue,
    lis.TotalQuantity,
    lis.TotalLineItems
FROM 
    RankedOrders ro
JOIN 
    LineItemSummary lis ON ro.o_orderkey = lis.l_orderkey
WHERE 
    ro.OrderRank <= 10
ORDER BY 
    ro.o_orderdate DESC, 
    TotalRevenue DESC;