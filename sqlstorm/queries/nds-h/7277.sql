WITH  supplier_parts AS (
    SELECT 
        s.s_suppkey AS supplier_id, 
        s.s_name AS supplier_name,
        p.p_partkey AS part_id, 
        p.p_name AS part_name, 
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        (ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 500.00
), aggregate_data AS (
    SELECT 
        supplier_id, 
        supplier_name, 
        COUNT(DISTINCT part_id) AS total_parts_supplied, 
        SUM(available_quantity) AS total_available_quantity,
        SUM(total_supply_value) AS total_supply_value
    FROM 
        supplier_parts
    GROUP BY 
        supplier_id, 
        supplier_name
), region_nation AS (
    SELECT 
        n.n_nationkey AS nation_id, 
        n.n_name AS nation_name, 
        r.r_regionkey AS region_id, 
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    a.supplier_id, 
    a.supplier_name, 
    a.total_parts_supplied, 
    a.total_available_quantity, 
    a.total_supply_value, 
    rn.region_name
FROM 
    aggregate_data a
JOIN 
    supplier s ON a.supplier_id = s.s_suppkey
JOIN 
    region_nation rn ON s.s_nationkey = rn.nation_id
WHERE 
    a.total_supply_value > 10000
ORDER BY 
    a.total_parts_supplied DESC, 
    a.total_supply_value DESC
LIMIT 10;
