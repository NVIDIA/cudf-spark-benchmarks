WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate >= DATE '1996-01-01') 
        AND c.c_acctbal IS NOT NULL
),
SupplierParts AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_availqty) AS TotalAvailable,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),
OrderLineSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalLinePrice,
        COUNT(DISTINCT l.l_partkey) AS DistinctParts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1996-01-01' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    ols.TotalLinePrice,
    ols.DistinctParts,
    sp.TotalAvailable,
    sp.TotalSupplyCost
FROM 
    RankedOrders ro
LEFT JOIN 
    OrderLineSummary ols ON ro.o_orderkey = ols.l_orderkey
LEFT JOIN 
    SupplierParts sp ON sp.TotalAvailable > 1000
WHERE 
    ro.OrderRank <= 10
ORDER BY 
    ro.o_orderdate DESC, 
    ro.o_totalprice DESC;