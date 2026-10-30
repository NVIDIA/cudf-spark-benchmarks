WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        c.c_acctbal > 1000
),
TopNations AS (
    SELECT 
        n.n_regionkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
    GROUP BY 
        n.n_regionkey
),
RegionRevenue AS (
    SELECT 
        r.r_name,
        COALESCE(tn.TotalRevenue, 0) AS TotalRevenue
    FROM 
        region r
    LEFT JOIN 
        TopNations tn ON r.r_regionkey = tn.n_regionkey
)
SELECT 
    rr.r_name,
    rr.TotalRevenue,
    COUNT(ro.o_orderkey) AS NumberOfHighValueOrders
FROM 
    RegionRevenue rr
LEFT JOIN 
    RankedOrders ro ON ro.o_orderdate >= '1996-01-01' AND ro.o_orderdate < '1997-01-01'
WHERE 
    ro.OrderRank <= 5
GROUP BY 
    rr.r_name, rr.TotalRevenue
ORDER BY 
    rr.TotalRevenue DESC
LIMIT 10;