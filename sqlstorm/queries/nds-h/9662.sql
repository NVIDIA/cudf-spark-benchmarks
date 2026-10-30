
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        SUM(rs.total_supply_cost) AS region_total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank <= 10
    GROUP BY 
        r.r_name
)
SELECT 
    ts.region_name,
    AVG(ts.region_total_cost) AS average_supply_cost,
    COUNT(ts.region_total_cost) AS supplier_count
FROM 
    TopSuppliers ts
GROUP BY 
    ts.region_name
ORDER BY 
    average_supply_cost DESC;
