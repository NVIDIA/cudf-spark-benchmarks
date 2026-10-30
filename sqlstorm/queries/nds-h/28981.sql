WITH String_Processing AS (
    SELECT 
        s.s_name AS supplier_name,
        SUBSTRING(s.s_address FROM 1 FOR 10) AS address_part,
        CONCAT('Supplier: ', s.s_name, ' from ', n.n_name) AS supplier_info,
        LENGTH(s.s_comment) AS comment_length,
        REPLACE(s.s_comment, 'poor', 'average') AS improved_comment,
        LOWER(s.s_name) AS lower_supplier_name,
        UPPER(s.s_name) AS upper_supplier_name,
        TRIM(s.s_comment) AS trimmed_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name LIKE 'A%'
),
Aggregated_Processing AS (
    SELECT 
        AVG(comment_length) AS avg_comment_length,
        COUNT(*) AS total_suppliers,
        COUNT(DISTINCT LOWER(supplier_name)) AS unique_supplier_names
    FROM 
        String_Processing
)
SELECT 
    supplier_name,
    address_part,
    supplier_info,
    improved_comment,
    (SELECT avg_comment_length FROM Aggregated_Processing) AS avg_length,
    (SELECT total_suppliers FROM Aggregated_Processing) AS total_count,
    (SELECT unique_supplier_names FROM Aggregated_Processing) AS unique_count
FROM 
    String_Processing
ORDER BY 
    supplier_name;
