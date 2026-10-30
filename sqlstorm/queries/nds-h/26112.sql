WITH string_benchmark AS (
    SELECT 
        p.p_partkey,
        CONCAT(p.p_name, ' - ', p.p_mfgr, ' [', p.p_type, ']') AS full_description,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_name) AS lower_name,
        LENGTH(p.p_name) AS name_length,
        REPLACE(p.p_comment, 'the', 'THE') AS modified_comment,
        SUBSTRING(p.p_name, 1, 10) AS name_substring
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
processed_strings AS (
    SELECT 
        fs.p_partkey,
        fs.full_description,
        fs.upper_name,
        fs.lower_name,
        fs.name_length,
        fs.modified_comment,
        fs.name_substring,
        (SELECT COUNT(*) FROM supplier s WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'N%')) AS supplier_count
    FROM 
        string_benchmark fs
)
SELECT 
    p.p_partkey,
    ps.full_description,
    ps.upper_name,
    ps.lower_name,
    ps.name_length,
    ps.modified_comment,
    ps.supplier_count
FROM 
    processed_strings ps
JOIN 
    part p ON p.p_partkey = ps.p_partkey
ORDER BY 
    ps.name_length DESC, 
    ps.supplier_count ASC
LIMIT 100;
