
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(p.ps_supplycost * p.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(p.ps_supplycost * p.ps_availqty) DESC) AS SupplierRank,
        n.n_name AS NationName
    FROM 
        supplier s
    JOIN 
        partsupp p ON s.s_suppkey = p.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
TopRegions AS (
    SELECT 
        n.n_name AS NationName,
        r.r_name AS RegionName,
        COUNT(DISTINCT s.s_suppkey) AS SupplierCount
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name, r.r_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 5
)
SELECT 
    tr.NationName,
    tr.RegionName,
    rs.s_name AS TopSupplier,
    rs.TotalSupplyCost,
    rs.s_acctbal
FROM 
    TopRegions tr
JOIN 
    RankedSuppliers rs ON tr.NationName = rs.NationName
WHERE 
    rs.SupplierRank = 1
ORDER BY 
    tr.RegionName, rs.TotalSupplyCost DESC;
