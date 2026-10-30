
WITH String_Bench AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        CONCAT(p.p_name, ' ', s.s_name) AS combined_name,
        LENGTH(CONCAT(p.p_name, ' ', s.s_name)) AS combined_length,
        LOWER(p.p_comment) AS lower_comment,
        UPPER(n.n_name) AS upper_nation,
        REPLACE(p.p_comment, 'special', 'standard') AS modified_comment,
        LEFT(p.p_name, 10) AS name_prefix,
        RIGHT(s.s_name, 5) AS name_suffix,
        POSITION('part' IN p.p_name) AS part_position,
        LPAD(CAST(p.p_partkey AS STRING) , 10, '0') AS padded_key 
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    part_name,
    supplier_name,
    nation_name,
    combined_name,
    combined_length,
    lower_comment,
    upper_nation,
    modified_comment,
    name_prefix,
    name_suffix,
    part_position,
    padded_key
FROM 
    String_Bench
WHERE 
    combined_length > 20
ORDER BY 
    combined_length DESC
LIMIT 100;
