
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank,
        p.p_partkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name, 
        p.p_type, 
        p.p_partkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS RegionName, 
        n.n_name AS NationName, 
        rs.s_name AS SupplierName, 
        rs.TotalCost
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON s.s_suppkey = rs.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.Rank <= 5
)
SELECT 
    RegionName, 
    NationName, 
    SupplierName, 
    TotalCost
FROM 
    TopSuppliers
ORDER BY 
    RegionName, 
    NationName, 
    TotalCost DESC;
