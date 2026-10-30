
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
), 
SupplierCosts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(sc.TotalSupplyCost) AS SupplierTotalCost
    FROM 
        supplier s
    JOIN 
        SupplierCosts sc ON s.s_suppkey = sc.ps_suppkey
    WHERE 
        s.s_acctbal > 10000
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(sc.TotalSupplyCost) > 50000
), 
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT l.l_partkey) AS UniqueParts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(od.TotalRevenue, 0) AS TotalRevenue,
    COALESCE(hs.SupplierTotalCost, 0) AS SupplierTotalCost,
    hs.s_name AS HighValueSupplier
FROM 
    RankedOrders r
LEFT JOIN 
    OrderDetails od ON r.o_orderkey = od.l_orderkey
LEFT JOIN 
    HighValueSuppliers hs ON r.o_orderkey IN (SELECT l.l_orderkey 
                                                FROM lineitem l 
                                                WHERE l.l_orderkey = r.o_orderkey)
WHERE 
    r.OrderRank = 1
ORDER BY 
    r.o_orderdate DESC, 
    r.o_totalprice ASC;
