WITH supplier_part_summary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_qty, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
nation_region_summary AS (
    SELECT 
        n.n_name AS nation_name, 
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(ps.total_available_qty) AS region_total_available_qty,
        SUM(ps.total_supply_cost) AS region_total_supply_cost
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier_part_summary ps ON n.n_nationkey = ps.s_suppkey
    JOIN 
        supplier s ON ps.s_suppkey = s.s_suppkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    nrs.region_name,
    nrs.nation_name,
    nrs.total_suppliers,
    nrs.region_total_available_qty,
    nrs.region_total_supply_cost,
    CASE 
        WHEN nrs.region_total_supply_cost > 1000000 THEN 'High Supply Cost'
        WHEN nrs.region_total_supply_cost BETWEEN 500000 AND 1000000 THEN 'Medium Supply Cost'
        ELSE 'Low Supply Cost'
    END AS supply_cost_category
FROM 
    nation_region_summary nrs
WHERE 
    nrs.total_suppliers > 10
ORDER BY 
    nrs.region_total_supply_cost DESC;
