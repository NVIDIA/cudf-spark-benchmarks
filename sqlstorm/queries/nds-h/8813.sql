
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS RegionName,
        COUNT(rs.s_suppkey) AS TopSupplierCount,
        SUM(rs.TotalSupplyCost) AS TotalCostInRegion
    FROM 
        region r
    JOIN 
        RankedSuppliers rs ON r.r_regionkey = rs.s_nationkey
    WHERE 
        rs.SupplierRank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    RegionName,
    TopSupplierCount,
    TotalCostInRegion
FROM 
    TopSuppliers
ORDER BY 
    TotalCostInRegion DESC;
