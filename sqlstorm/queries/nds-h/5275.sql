WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
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
        rs.total_supplycost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.rank <= 10 AND n.n_nationkey = rs.s_suppkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    r.r_name AS Region,
    COUNT(ts.s_name) AS Top_Suppliers_Count,
    SUM(ts.total_supplycost) AS Total_Cost
FROM 
    TopSuppliers ts
JOIN 
    region r ON ts.r_name = r.r_name
GROUP BY 
    r.r_name
ORDER BY 
    Total_Cost DESC;
