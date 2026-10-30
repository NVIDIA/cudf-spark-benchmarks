
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
        SUM(rs.total_supply_cost) AS total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.nation_name = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    t.region_name,
    t.supplier_count,
    t.total_supply_cost,
    ROUND(t.total_supply_cost / NULLIF(t.supplier_count, 0), 2) AS avg_supply_cost_per_supplier
FROM 
    TopSuppliers t
ORDER BY 
    t.total_supply_cost DESC;
