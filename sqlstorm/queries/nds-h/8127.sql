WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name, 
        COUNT(rs.s_suppkey) AS SupplierCount, 
        SUM(rs.TotalCost) AS RegionTotalCost
    FROM 
        region r
    JOIN 
        RankedSuppliers rs ON r.r_regionkey = rs.Rnk
    WHERE 
        rs.Rnk <= 3
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    t.SupplierCount,
    t.RegionTotalCost,
    AVG(t.RegionTotalCost) OVER() AS AverageRegionCost
FROM 
    TopSuppliers t
JOIN 
    region r ON r.r_name = t.r_name
ORDER BY 
    t.RegionTotalCost DESC
LIMIT 5;
