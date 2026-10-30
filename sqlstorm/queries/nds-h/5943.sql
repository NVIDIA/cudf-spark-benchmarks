
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),

TopSuppliers AS (
    SELECT 
        r.r_name AS Region,
        n.n_name AS Nation,
        rs.s_name AS Supplier,
        rs.TotalSupplyCost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.SupplierRank <= 3
)

SELECT 
    t.Region,
    t.Nation,
    COUNT(DISTINCT t.Supplier) AS TopSupplierCount,
    SUM(t.TotalSupplyCost) AS TotalTopSupplierCost
FROM 
    TopSuppliers t
GROUP BY 
    t.Region, t.Nation
ORDER BY 
    TotalTopSupplierCost DESC, t.Region, t.Nation;
