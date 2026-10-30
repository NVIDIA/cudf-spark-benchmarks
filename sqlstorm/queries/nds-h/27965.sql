WITH String_Analysis AS (
    SELECT 
        p.p_name AS part_name,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_name) AS name_upper,
        LOWER(p.p_name) AS name_lower,
        REPLACE(p.p_comment, 'NEW', 'OLD') AS modified_comment,
        SUBSTR(p.p_comment, 1, 10) AS comment_excerpt,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        p.p_name, p.p_comment
)
SELECT 
    part_name,
    name_length,
    name_upper,
    name_lower,
    modified_comment,
    comment_excerpt,
    supplier_count,
    order_count
FROM 
    String_Analysis
WHERE 
    name_length > 10
ORDER BY 
    supplier_count DESC, order_count ASC;
