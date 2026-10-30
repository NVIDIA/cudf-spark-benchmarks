
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank,
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
        r.r_name AS region_name,
        s.s_name,
        s.total_supply_cost,
        n.n_nationkey
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.n_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.supplier_rank <= 3
)
SELECT 
    region_name,
    COUNT(*) AS number_of_top_suppliers,
    SUM(total_supply_cost) AS total_cost_by_region
FROM 
    TopSuppliers
GROUP BY 
    region_name
ORDER BY 
    total_cost_by_region DESC;
