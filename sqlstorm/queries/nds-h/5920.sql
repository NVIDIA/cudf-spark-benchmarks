WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS PriceRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS UniquePartsSupplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
TopSuppliers AS (
    SELECT 
        ss.s_suppkey, 
        ss.s_name, 
        ss.TotalSupplyCost,
        ss.UniquePartsSupplied,
        RANK() OVER (ORDER BY ss.TotalSupplyCost DESC) AS SupplierRank
    FROM 
        SupplierStats ss
    WHERE 
        ss.UniquePartsSupplied > 10
)
SELECT 
    ro.o_orderkey, 
    ro.o_orderdate, 
    ro.o_totalprice, 
    ts.s_name AS TopSupplierName, 
    ts.TotalSupplyCost
FROM 
    RankedOrders ro
JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE 
    ro.PriceRank <= 5 
ORDER BY 
    ro.o_orderdate, ts.TotalSupplyCost DESC;