WITH StringProcessing AS (
    SELECT 
        p.p_name,
        CONCAT('Supplier:', s.s_name, ', part:', p.p_name, ', Order:', o.o_orderkey) AS detailed_info,
        LENGTH(CONCAT('Supplier:', s.s_name, ', part:', p.p_name, ', Order:', o.o_orderkey)) AS info_length,
        REPLACE(REPLACE(s.s_comment, 'bad', 'good'), 'average', 'excellent') AS modified_comment,
        LOWER(p.p_comment) AS lower_comment,
        UPPER(o.o_comment) AS upper_order_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
)
SELECT 
    p_name,
    detailed_info,
    info_length,
    modified_comment,
    lower_comment,
    upper_order_comment
FROM 
    StringProcessing
WHERE 
    info_length > 100
ORDER BY 
    info_length DESC
LIMIT 50;
