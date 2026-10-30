
WITH PartSupplierInfo AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        s.s_address AS supplier_address,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        p.p_comment AS part_comment,
        CONCAT(s.s_name, ' - ', s.s_address) AS supplier_details,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
FilteredInfo AS (
    SELECT 
        part_name,
        supplier_name,
        supplier_address,
        available_quantity,
        supply_cost,
        part_comment,
        supplier_details,
        comment_length
    FROM 
        PartSupplierInfo
    WHERE 
        available_quantity > 50 AND
        comment_length > 20
)
SELECT 
    part_name,
    supplier_name,
    supplier_address,
    available_quantity,
    supply_cost,
    supplier_details,
    INITCAP(part_comment) AS formatted_comment
FROM 
    FilteredInfo
ORDER BY 
    supply_cost DESC, 
    part_name ASC;
