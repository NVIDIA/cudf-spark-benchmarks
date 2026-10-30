WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank,
        COUNT(*) OVER (PARTITION BY o.o_orderstatus) AS TotalOrders
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT p.p_partkey) AS PartCount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
),
HighestCostSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.TotalSupplyCost,
        sd.PartCount
    FROM 
        SupplierDetails sd
    WHERE 
        sd.TotalSupplyCost > (SELECT AVG(TotalSupplyCost) FROM SupplierDetails)
)

SELECT 
    r.n_name AS NationName,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
    COALESCE(MAX(ro.o_totalprice), 0) AS MaxOrderPrice,
    COUNT(DISTINCT l.l_orderkey) AS DistinctOrderCount
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation r ON c.c_nationkey = r.n_nationkey
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey = o.o_orderkey AND ro.OrderRank = 1
INNER JOIN 
    HighestCostSuppliers hcs ON l.l_suppkey = hcs.s_suppkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
GROUP BY 
    r.n_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 10 
    AND SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    Revenue DESC
LIMIT 100;