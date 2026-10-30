WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        COUNT(DISTINCT p.p_partkey) AS PartCount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationInfo AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(si.TotalCost) AS TotalSupplierCost,
        SUM(si.PartCount) AS TotalPartsSupplied
    FROM 
        SupplierInfo si
    JOIN 
        nation n ON si.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
RegionCost AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(ni.TotalSupplierCost) AS TotalRegionCost,
        COUNT(ni.n_nationkey) AS TotalNations
    FROM 
        nationinfo ni
    JOIN 
        nation n ON ni.n_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    rc.r_name,
    rc.TotalRegionCost,
    rc.TotalNations
FROM 
    RegionCost rc
ORDER BY 
    rc.TotalRegionCost DESC
LIMIT 10;
