
WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_brand AS part_brand,
        ps.ps_supplycost AS supply_cost,
        ps.ps_availqty AS available_quantity,
        CONCAT(CAST(EXTRACT(YEAR FROM CURRENT_DATE) AS STRING), '-', 
               LPAD(CAST(EXTRACT(MONTH FROM CURRENT_DATE) AS STRING), 2, '0'), '-', 
               LPAD(CAST(EXTRACT(DAY FROM CURRENT_DATE) AS STRING), 2, '0')) AS as_of_date
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    supplier_name,
    COUNT(DISTINCT part_name) AS total_parts,
    SUM(supply_cost * available_quantity) AS total_inventory_value,
    STRING_AGG(part_name, ', ') AS part_names_list,
    STRING_AGG(DISTINCT part_brand, ', ') AS unique_brands
FROM 
    SupplierParts
GROUP BY 
    supplier_name
HAVING 
    COUNT(DISTINCT part_name) > 3
ORDER BY 
    total_inventory_value DESC;
