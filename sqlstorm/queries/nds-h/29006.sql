
WITH StringProcessing AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        o.o_orderkey,
        CONCAT(UPPER(p.p_comment), '|', LOWER(s.s_comment), '|', INITCAP(c.c_comment)) AS processed_comments,
        LENGTH(CONCAT(UPPER(p.p_comment), '|', LOWER(s.s_comment), '|', INITCAP(c.c_comment))) AS total_length
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
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        p.p_name LIKE 'S%' 
        AND s.s_phone LIKE '123%' 
        AND c.c_mktsegment = 'BUILD'
)
SELECT 
    part_name, 
    supplier_name, 
    customer_name, 
    COUNT(DISTINCT o_orderkey) AS order_count,
    SUM(total_length) AS total_processed_length
FROM 
    StringProcessing
GROUP BY 
    part_name, 
    supplier_name, 
    customer_name
ORDER BY 
    total_processed_length DESC;
