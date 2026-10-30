WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_regionkey
), 
TopEconomicalSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        s.s_name AS supplier_name,
        s.total_supply_cost
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.supplier_rank <= 3
)
SELECT 
    t.region_name,
    COUNT(*) AS top_supplier_count,
    SUM(t.total_supply_cost) AS total_cost
FROM 
    TopEconomicalSuppliers t
GROUP BY 
    t.region_name
ORDER BY 
    total_cost DESC;
