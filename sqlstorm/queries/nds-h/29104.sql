
WITH String_Processing AS (
    SELECT 
        p.p_name,
        CONCAT('Manufacturer: ', p.p_mfgr, ', Type: ', p.p_type, ', Size: ', CAST(p.p_size AS STRING), 
               ', Price: $', CAST(p.p_retailprice AS DECIMAL(12, 2)), ', Comment: ', p.p_comment) AS formatted_string,
        p.p_partkey
    FROM 
        part p
)
SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts,
    STRING_AGG(sp.formatted_string, '; ') AS combined_strings
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    String_Processing sp ON ps.ps_partkey = sp.p_partkey
GROUP BY 
    s.s_name
ORDER BY 
    total_parts DESC
LIMIT 10;
