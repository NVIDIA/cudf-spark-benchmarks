WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        CONCAT(p.p_name, ' - ', s.s_name) AS combined_name,
        LENGTH(CONCAT(p.p_name, ' - ', s.s_name)) AS combined_length,
        REPLACE(SUBSTRING(p.p_comment, 1, 10), ' ', '_') AS modified_comment,
        LOWER(p.p_type) AS lower_type,
        UPPER(s.s_name) AS upper_supplier_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size BETWEEN 5 AND 10 
        AND s.s_acctbal > 5000
)
SELECT 
    combined_name,
    combined_length,
    modified_comment,
    lower_type,
    upper_supplier_name
FROM 
    StringProcessing
ORDER BY 
    combined_length DESC, 
    upper_supplier_name ASC;
