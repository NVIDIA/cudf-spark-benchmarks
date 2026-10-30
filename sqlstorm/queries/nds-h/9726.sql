
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk,
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
        r.r_name, 
        rs.s_name, 
        rs.TotalSupplyCost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.n_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rnk <= 3
)
SELECT 
    r.r_name AS Region, 
    COUNT(*) AS SupplierCount, 
    SUM(ts.TotalSupplyCost) AS TotalCost
FROM 
    TopSuppliers ts
JOIN 
    region r ON ts.r_name = r.r_name
GROUP BY 
    r.r_name
ORDER BY 
    TotalCost DESC;
