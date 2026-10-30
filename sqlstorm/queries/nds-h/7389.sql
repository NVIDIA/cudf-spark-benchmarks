
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        s.s_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.total_available_qty,
        rs.total_supply_cost,
        n.n_name AS nation_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank <= 5
)
SELECT 
    ts.nation_name,
    COUNT(DISTINCT ts.s_suppkey) AS number_of_suppliers,
    SUM(ts.total_available_qty) AS total_inventory,
    AVG(ts.total_supply_cost) AS avg_supply_cost
FROM 
    TopSuppliers ts
GROUP BY 
    ts.nation_name
ORDER BY 
    total_inventory DESC, avg_supply_cost ASC;
