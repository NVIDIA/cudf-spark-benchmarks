
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
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
        ns.n_name,
        rs.s_name,
        rs.total_supply_cost,
        ns.n_nationkey
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.rank = 1 AND ns.n_nationkey = rs.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
)
SELECT 
    r.r_name AS Region,
    ns.n_name AS Nation,
    COUNT(rs.s_name) AS Top_Supplier_Count,
    SUM(rs.total_supply_cost) AS Total_Supply_Cost
FROM 
    TopSuppliers rs
JOIN 
    region r ON rs.r_name = r.r_name
JOIN 
    nation ns ON rs.n_name = ns.n_name
GROUP BY 
    r.r_name, ns.n_name
ORDER BY 
    r.r_name, Total_Supply_Cost DESC;
