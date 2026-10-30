WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
),    
TotalRevenue AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue
    FROM 
        lineitem l
    JOIN 
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name AS Nation,
    r.r_name AS Region,
    COUNT(DISTINCT ro.o_orderkey) AS TotalOrders,
    SUM(tr.Revenue) AS TotalRevenue,
    AVG(ro.o_totalprice) AS AvgOrderValue,
    MAX(ro.o_orderdate) AS LatestOrderDate
FROM 
    TotalRevenue tr
JOIN 
    orders ro ON tr.l_orderkey = ro.o_orderkey
JOIN 
    customer c ON ro.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    tr.Revenue > 1000
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT ro.o_orderkey) > 10
ORDER BY 
    TotalRevenue DESC;