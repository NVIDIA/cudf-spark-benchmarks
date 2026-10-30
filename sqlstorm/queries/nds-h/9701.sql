WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_in_region
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
HighCostSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        s.s_name AS supplier_name,
        s.total_cost
    FROM 
        RankedSuppliers s
    JOIN 
        region r ON s.rank_in_region = 1 
    WHERE 
        s.total_cost > (
            SELECT AVG(total_cost) FROM RankedSuppliers
        )
)
SELECT 
    h.region_name,
    COUNT(h.supplier_name) AS number_of_suppliers,
    SUM(h.total_cost) AS total_high_cost
FROM 
    HighCostSuppliers h
GROUP BY 
    h.region_name
ORDER BY 
    total_high_cost DESC;
