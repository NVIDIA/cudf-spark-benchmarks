WITH string_processing AS (
    SELECT 
        p.p_name,
        s.s_name,
        n.n_name,
        CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Nation: ', n.n_name) AS combined_info,
        LENGTH(p.p_name) AS part_name_length,
        LENGTH(s.s_name) AS supplier_name_length,
        LENGTH(n.n_name) AS nation_name_length,
        REPLACE(UPPER(p.p_comment), ' ', '_') AS formatted_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_size > 10 AND
        s.s_acctbal > 1000.00
)
SELECT 
    combined_info,
    part_name_length,
    supplier_name_length,
    nation_name_length,
    formatted_comment
FROM 
    string_processing
WHERE 
    part_name_length > 20
ORDER BY 
    part_name_length DESC, supplier_name_length ASC;
