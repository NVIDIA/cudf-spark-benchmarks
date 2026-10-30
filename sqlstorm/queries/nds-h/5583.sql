WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * li.l_quantity) AS TotalSupplyCost,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalRevenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem li ON ps.ps_partkey = li.l_partkey
    JOIN 
        orders o ON li.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        li.l_shipdate >= '1997-01-01' AND 
        li.l_shipdate < '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionPerformance AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(sp.TotalSupplyCost) AS TotalSupplyCost,
        SUM(sp.TotalRevenue) AS TotalRevenue,
        COUNT(sp.TotalOrders) AS TotalOrderCount
    FROM 
        SupplierPerformance sp
    JOIN 
        supplier s ON sp.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    r.r_name,
    r.TotalSupplyCost,
    r.TotalRevenue,
    r.TotalOrderCount,
    (r.TotalRevenue / NULLIF(r.TotalOrderCount, 0)) AS AverageOrderValue
FROM 
    RegionPerformance r
ORDER BY 
    r.TotalRevenue DESC
LIMIT 10;