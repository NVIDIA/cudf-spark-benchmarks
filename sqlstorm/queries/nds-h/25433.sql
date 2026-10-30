WITH processed_data AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        concat('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Customer: ', c.c_name) AS details,
        LEFT(p.p_comment, 10) || '...' AS short_comment,
        LENGTH(p.p_comment) AS comment_length
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
        p.p_size > 10 AND 
        s.s_acctbal > 1000.00
)
SELECT 
    part_name, 
    supplier_name,
    customer_name,
    details,
    short_comment,
    comment_length,
    TRIM(BOTH ' ' FROM details) AS trimmed_details
FROM 
    processed_data
ORDER BY 
    comment_length DESC
LIMIT 50;
