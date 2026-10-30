WITH part_supplier_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        p.p_type,
        s.s_nationkey
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_type, s.s_nationkey
),
nation_summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(pss.total_available_quantity) AS total_part_quantity,
        SUM(pss.total_supply_value) AS total_value_of_parts
    FROM 
        nation n
    JOIN 
        part_supplier_summary pss ON n.n_nationkey = pss.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name,
    n.total_part_quantity,
    n.total_value_of_parts,
    CASE 
        WHEN n.total_part_quantity > 1000 THEN 'High Supply'
        WHEN n.total_part_quantity BETWEEN 500 AND 1000 THEN 'Medium Supply'
        ELSE 'Low Supply'
    END AS supply_category
FROM 
    nation_summary n
WHERE 
    n.total_value_of_parts > 100000
ORDER BY 
    n.total_value_of_parts DESC
LIMIT 10;
