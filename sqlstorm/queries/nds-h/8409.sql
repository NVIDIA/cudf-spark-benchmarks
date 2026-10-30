WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS RankInRegion
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS RegionName,
        rs.s_name AS SupplierName,
        rs.TotalSupplyCost
    FROM 
        RankedSuppliers rs
    JOIN 
        region r ON rs.RankInRegion < 3
)
SELECT 
    RegionName,
    SupplierName,
    TotalSupplyCost
FROM 
    TopSuppliers
ORDER BY 
    RegionName, TotalSupplyCost DESC;
