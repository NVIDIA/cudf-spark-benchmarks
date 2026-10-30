WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS combined_string,
        LENGTH(CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name)) AS string_length,
        UPPER(CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name)) AS uppercase_string,
        LOWER(CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name)) AS lowercase_string,
        REPLACE(CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name), ' ', '-') AS replaced_string
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    p_partkey, 
    p_name, 
    supplier_name, 
    combined_string, 
    string_length, 
    uppercase_string, 
    lowercase_string, 
    replaced_string
FROM 
    StringProcessing
WHERE 
    string_length > 50
ORDER BY 
    string_length DESC
LIMIT 10;
