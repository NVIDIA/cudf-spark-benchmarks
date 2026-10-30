WITH RegionalStats AS (
    SELECT 
        r.r_name AS RegionName,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
        COUNT(DISTINCT c.c_custkey) AS TotalCustomers
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
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        l.l_shipdate >= '1995-01-01' AND l.l_shipdate < '1995-04-01'
    GROUP BY 
        r.r_name
),
RankedStats AS (
    SELECT 
        RegionName,
        TotalRevenue,
        TotalOrders,
        TotalCustomers,
        RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank
    FROM 
        RegionalStats
)
SELECT 
    RegionName,
    TotalRevenue,
    TotalOrders,
    TotalCustomers,
    RevenueRank
FROM 
    RankedStats
WHERE 
    TotalOrders > 0
ORDER BY 
    RevenueRank;