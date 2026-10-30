WITH RegionSales AS (
    SELECT 
        r.r_name AS Region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
), AverageRevenue AS (
    SELECT 
        AVG(TotalRevenue) AS AvgRevenue
    FROM 
        RegionSales
), TopRegions AS (
    SELECT 
        Region,
        TotalRevenue,
        RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank
    FROM 
        RegionSales
)
SELECT 
    tr.Region,
    tr.TotalRevenue,
    ar.AvgRevenue,
    CASE 
        WHEN tr.TotalRevenue > ar.AvgRevenue THEN 'Above Average'
        WHEN tr.TotalRevenue < ar.AvgRevenue THEN 'Below Average'
        ELSE 'Average'
    END AS RevenueComparison
FROM 
    TopRegions tr, AverageRevenue ar
WHERE 
    tr.RevenueRank <= 5
ORDER BY 
    tr.TotalRevenue DESC;
