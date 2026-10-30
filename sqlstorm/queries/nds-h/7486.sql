WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_type
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        ts.s_name,
        ts.total_supply_cost
    FROM 
        RankedSuppliers ts
    JOIN 
        supplier s ON ts.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ts.rank_cost <= 5
)
SELECT 
    ts.region_name,
    COUNT(ts.s_name) AS top_supplier_count,
    SUM(ts.total_supply_cost) AS total_cost_per_region
FROM 
    TopSuppliers ts
GROUP BY 
    ts.region_name
ORDER BY 
    total_cost_per_region DESC;
