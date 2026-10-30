
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank,
        n.n_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS Region, 
        ns.n_name AS Nation, 
        rs.s_name AS SupplierName, 
        rs.TotalCost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.Rank = 1 AND rs.n_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
)
SELECT 
    Region, 
    Nation, 
    SupplierName, 
    TotalCost
FROM 
    TopSuppliers
ORDER BY 
    Region, Nation, TotalCost DESC;
