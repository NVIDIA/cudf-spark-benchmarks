WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
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
Summary AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT r.r_regionkey) AS regions_count,
        SUM(r_cost.total_cost) AS total_supplier_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        RankedSuppliers r_cost ON r_cost.rank = 1
    GROUP BY 
        n.n_name
)
SELECT 
    nation_name,
    regions_count,
    total_supplier_cost,
    total_supplier_cost / NULLIF(regions_count, 0) AS avg_cost_per_region
FROM 
    Summary
ORDER BY 
    total_supplier_cost DESC, nation_name ASC;
