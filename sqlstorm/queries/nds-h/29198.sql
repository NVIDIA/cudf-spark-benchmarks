WITH  string_benchmark AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_name) AS lower_name,
        LENGTH(p.p_name) AS name_length,
        CONCAT(p.p_name, ' contains the word "part"') AS modified_name
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%part%'
    
    UNION ALL
    
    SELECT 
        ps.ps_partkey,
        CONCAT('Supplier for Part ', p.p_name),
        UPPER(CONCAT('Supplier for Part ', p.p_name)),
        LOWER(CONCAT('Supplier for Part ', p.p_name)),
        LENGTH(CONCAT('Supplier for Part ', p.p_name)),
        CONCAT(CONCAT('Supplier for Part ', p.p_name), ' - available')
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT sb.p_partkey) AS part_count,
    SUM(sb.name_length) AS total_length,
    AVG(sb.name_length) AS average_length,
    STRING_AGG(DISTINCT sb.modified_name, '; ') AS combined_modified_names
FROM 
    string_benchmark sb
JOIN 
    partsupp ps ON sb.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    s.s_name
ORDER BY 
    part_count DESC;
