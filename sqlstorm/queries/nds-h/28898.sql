WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name) AS supplier_part_description,
        LENGTH(CONCAT(s.s_name, ' supplies ', p.p_name)) AS description_length
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
EnhancedOutput AS (
    SELECT 
        supplier_name,
        part_name,
        available_quantity,
        supply_cost,
        supplier_part_description,
        description_length,
        (CASE 
            WHEN description_length < 20 THEN 'Short Description'
            WHEN description_length BETWEEN 20 AND 50 THEN 'Medium Description'
            ELSE 'Long Description' 
        END) AS description_category
    FROM 
        SupplierParts
)
SELECT 
    supplier_name,
    part_name,
    available_quantity,
    supply_cost,
    supplier_part_description,
    description_length,
    description_category
FROM 
    EnhancedOutput
WHERE 
    available_quantity > 100 AND 
    supply_cost < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    supplier_name, part_name;
