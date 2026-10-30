
WITH StringAggregates AS (
    SELECT 
        p.p_name AS part_name, 
        CONCAT('Brand: ', p.p_brand, ', Type: ', p.p_type) AS part_description,
        LENGTH(p.p_comment) AS comment_length,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_comment
),
FilteredParts AS (
    SELECT 
        part_name, 
        part_description, 
        comment_length, 
        supplier_count, 
        supplier_names
    FROM 
        StringAggregates
    WHERE 
        comment_length > 20 AND supplier_count > 1
)
SELECT 
    part_name,
    UPPER(part_description) AS upper_description,
    LOWER(supplier_names) AS lower_suppliers,
    CONCAT('Part: ', part_name, ' | Suppliers: ', supplier_names) AS detailed_info
FROM 
    FilteredParts
ORDER BY 
    comment_length DESC
LIMIT 10;
