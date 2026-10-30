WITH RegionalSales AS (
    SELECT 
        r.r_name AS Region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
        AND l.l_shipmode IN ('AIR', 'GROUND')
    GROUP BY 
        r.r_name
),
SalesRanked AS (
    SELECT 
        Region,
        TotalSales,
        OrderCount,
        RANK() OVER (ORDER BY TotalSales DESC) AS SalesRank
    FROM 
        RegionalSales
),
TopRegions AS (
    SELECT 
        Region, 
        TotalSales, 
        OrderCount
    FROM 
        SalesRanked
    WHERE 
        SalesRank <= 5
)

SELECT 
    t.Region,
    t.TotalSales,
    t.OrderCount,
    COALESCE(s.s_acctbal, 0) AS SupplierBalance,
    CASE 
        WHEN t.OrderCount > 0 THEN ROUND(t.TotalSales / t.OrderCount, 2) 
        ELSE NULL 
    END AS AverageOrderValue
FROM 
    TopRegions t
LEFT JOIN 
    supplier s ON s.s_suppkey IN (
        SELECT 
            ps.ps_suppkey
        FROM 
            partsupp ps
        JOIN 
            part p ON p.p_partkey = ps.ps_partkey
        WHERE 
            p.p_size >= 20
    )
ORDER BY 
    t.TotalSales DESC, 
    t.Region;