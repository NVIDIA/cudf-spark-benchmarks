WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
SupplierAggregates AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS OrderCount
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS DistinctOrderCount,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS TotalRevenue,
    AVG(CASE WHEN r.OrderRank <= 10 THEN o.o_totalprice ELSE NULL END) AS AvgTopOrderPrice,
    s.TotalSupplyCost
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierAggregates s ON s.ps_suppkey = (SELECT ps.ps_suppkey 
                                             FROM partsupp ps 
                                             WHERE ps.ps_partkey = (SELECT p.p_partkey 
                                                                    FROM part p 
                                                                    WHERE p.p_size > 10 
                                                                      AND p.p_retailprice < 500.00 
                                                                    LIMIT 1)
                                             LIMIT 1)
LEFT JOIN 
    RankedOrders r ON o.o_orderkey = r.o_orderkey
WHERE 
    c.c_acctbal > 100.00
GROUP BY 
    c.c_name, s.TotalSupplyCost
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    TotalRevenue DESC, DistinctOrderCount ASC;