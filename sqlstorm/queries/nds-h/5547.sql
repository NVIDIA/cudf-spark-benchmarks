WITH TotalSales AS (
    SELECT 
        n.n_name AS Nation,
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
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        n.n_name
),
HighRevenueNations AS (
    SELECT 
        Nation,
        TotalRevenue,
        RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank
    FROM 
        TotalSales
)

SELECT 
    h.Nation,
    h.TotalRevenue,
    ROUND(h.TotalRevenue / (SELECT SUM(TotalRevenue) FROM TotalSales) * 100, 2) AS RevenuePercentage
FROM 
    HighRevenueNations h
WHERE 
    h.RevenueRank <= 5
ORDER BY 
    h.TotalRevenue DESC;