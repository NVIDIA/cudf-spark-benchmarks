WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS RevenueRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_mktsegment
),

HighestRevenue AS (
    SELECT 
        RevenueRank, 
        o_orderkey, 
        o_orderdate, 
        c_mktsegment, 
        TotalRevenue
    FROM 
        RankedOrders
    WHERE 
        RevenueRank = 1
)

SELECT 
    n.n_name AS Nation,
    SUM(hr.TotalRevenue) AS TotalTopRevenue
FROM 
    HighestRevenue hr
LEFT JOIN 
    supplier s ON hr.o_orderkey = s.s_suppkey  
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
HAVING 
    SUM(hr.TotalRevenue) IS NOT NULL
ORDER BY 
    TotalTopRevenue DESC;