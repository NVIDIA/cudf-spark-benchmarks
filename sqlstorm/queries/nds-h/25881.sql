WITH supplier_part_details AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        (ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        s.s_comment AS supplier_comment,
        p.p_comment AS part_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
region_summary AS (
    SELECT
        r.r_name AS region_name,
        SUM(sp.total_cost) AS total_supply_cost,
        COUNT(sp.supplier_name) AS total_suppliers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        supplier_part_details sp ON s.s_name = sp.supplier_name
    GROUP BY 
        r.r_name
),
part_name_summary AS (
    SELECT 
        p.p_name AS part_name,
        COUNT(ps.ps_partkey) AS total_suppliers,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name
)
SELECT 
    r.region_name,
    r.total_supply_cost,
    r.total_suppliers,
    p.part_name,
    p.total_suppliers AS suppliers_for_part,
    p.total_supply_cost AS part_supply_cost
FROM 
    region_summary r
LEFT JOIN 
    part_name_summary p ON r.total_supply_cost > p.total_supply_cost
ORDER BY 
    r.total_supply_cost DESC, p.total_supply_cost ASC;
