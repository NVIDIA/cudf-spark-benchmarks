WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderpriority,
        c.c_name,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC, o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND o.o_orderdate >= DATE '1996-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS PartCount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.TotalSupplyCost,
        ss.PartCount,
        RANK() OVER (ORDER BY ss.TotalSupplyCost DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    ro.c_mktsegment,
    ts.s_name,
    ts.TotalSupplyCost,
    ts.PartCount
FROM 
    RankedOrders ro
JOIN 
    lineitem li ON ro.o_orderkey = li.l_orderkey
JOIN 
    TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
WHERE 
    ro.OrderRank <= 10
    AND ts.SupplierRank <= 5
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC;