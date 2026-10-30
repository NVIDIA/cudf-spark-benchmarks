WITH  RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1994-01-01' AND o.o_orderdate < DATE '1995-01-01'
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        n.n_regionkey,
        r.r_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplierCost
    FROM 
        supplier s
    INNER JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    INNER JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, n.n_regionkey, r.r_name
),
LineItemMetrics AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS LineItemCount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        AVG(l.l_quantity) AS AvgQuantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    sr.r_name AS SupplierRegion,
    lm.LineItemCount,
    lm.TotalRevenue,
    lm.AvgQuantity
FROM 
    RankedOrders o
LEFT JOIN 
    LineItemMetrics lm ON o.o_orderkey = lm.l_orderkey
LEFT JOIN 
    SupplierRegion sr ON lm.LineItemCount > 0
WHERE 
    o.o_orderstatus IN ('F', 'O')
ORDER BY 
    o.o_totalprice DESC, 
    lm.TotalRevenue ASC
LIMIT 10;