
WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        p.p_comment AS part_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueParts AS (
    SELECT 
        supplier_name,
        part_name,
        available_quantity,
        supply_cost,
        part_comment,
        CONCAT('Supplier: ', supplier_name, ', Part: ', part_name, 
               ', Available Qty: ', available_quantity, 
               ', Supply Cost: $', CAST(supply_cost AS STRING), 
               ', Comment: ', part_comment) AS detailed_comment
    FROM 
        SupplierParts
    WHERE 
        supply_cost > (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT 
    LENGTH(detailed_comment) AS comment_length,
    SUBSTRING(detailed_comment, 1, 100) AS preview_comment
FROM 
    HighValueParts
ORDER BY 
    comment_length DESC
LIMIT 10;
