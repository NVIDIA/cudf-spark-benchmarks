
WITH processed_data AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        n.n_name AS nation_name,
        CONCAT('Part: ', p.p_name, ' | Brand: ', p.p_brand, ' | Supplier: ', s.s_name, ' | Customer: ', c.c_name) AS summary,
        LENGTH(p.p_comment) AS comment_length,
        SUBSTRING(p.p_comment, 1, 10) AS shortened_comment
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
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_size = (SELECT MAX(p2.p_size) FROM part p2)
    ORDER BY 
        o.o_orderdate DESC
)
SELECT 
    summary,
    AVG(comment_length) AS avg_comment_length,
    COUNT(*) AS total_entries
FROM 
    processed_data
GROUP BY 
    summary
HAVING 
    COUNT(*) > 1
ORDER BY 
    avg_comment_length DESC;
