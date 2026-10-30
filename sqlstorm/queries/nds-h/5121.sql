WITH RevenueData AS (
    SELECT 
        n.n_name AS Nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        n.n_name
),
TopNations AS (
    SELECT 
        Nation,
        TotalRevenue,
        OrderCount,
        RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank
    FROM 
        RevenueData
)
SELECT 
    tn.Nation,
    tn.TotalRevenue,
    tn.OrderCount,
    rd.TotalRevenue / SUM(rd.TotalRevenue) OVER () AS RevenueShare
FROM 
    TopNations tn
JOIN 
    RevenueData rd ON tn.Nation = rd.Nation
WHERE 
    tn.RevenueRank <= 5
ORDER BY 
    tn.TotalRevenue DESC;