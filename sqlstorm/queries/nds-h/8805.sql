
WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank,
        n.n_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS Region,
        s.s_name AS Supplier,
        s.TotalCost
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.n_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.Rank <= 5
)
SELECT 
    ts.Region,
    ts.Supplier,
    ts.TotalCost
FROM 
    TopSuppliers ts
ORDER BY 
    ts.Region, ts.TotalCost DESC;
