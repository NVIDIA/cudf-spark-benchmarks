WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND 
        o.o_orderdate < '1998-01-01'
),
AggregateSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS NetRevenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    cs.c_name,
    cs.OrderCount,
    cs.TotalSpent,
    COALESCE(ls.NetRevenue, 0) AS TotalLineItemRevenue,
    s.TotalCost AS SupplierTotalCost
FROM 
    RankedOrders r
JOIN 
    CustomerOrders cs ON r.o_orderkey = cs.c_custkey
LEFT JOIN 
    LineItemSummary ls ON r.o_orderkey = ls.l_orderkey
LEFT JOIN 
    AggregateSupplier s ON s.s_suppkey = cs.c_custkey
WHERE 
    r.OrderRank = 1
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;