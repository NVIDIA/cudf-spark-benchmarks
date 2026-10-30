WITH StringAnalysis AS (
    SELECT 
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        SUBSTRING(p.p_name FROM 1 FOR 10) AS first_ten_chars,
        REPLACE(p.p_comment, 'failed', 'succeeded') AS updated_comment,
        CONCAT(s.s_name, ' | ', n.n_name) AS supplier_location,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        LENGTH(p.p_name) > 5 AND 
        p.p_comment LIKE '%special%'
    GROUP BY 
        p.p_name, p.p_comment, s.s_name, n.n_name
)
SELECT 
    sa.p_name, 
    sa.name_length,
    sa.first_ten_chars, 
    sa.updated_comment,
    sa.supplier_location,
    sa.total_orders
FROM 
    StringAnalysis sa
ORDER BY 
    sa.name_length DESC, 
    sa.total_orders DESC
LIMIT 50;
