SELECT 
    p.p_name,
    CONCAT(LEFT(p.p_name, 3), '-', RIGHT(p.p_name, 3), ' (', p.p_size, ')') AS formatted_name,
    s.s_name,
    c.c_name,
    l.l_orderkey,
    SUBSTR(l.l_comment, 1, 20) AS short_comment,
    COUNT(DISTINCT l.l_linenumber) AS line_item_count
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
    LENGTH(p.p_name) > 10 AND 
    s.s_acctbal > 1000.00 AND 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, formatted_name, s.s_name, c.c_name, l.l_orderkey, short_comment
ORDER BY 
    line_item_count DESC
LIMIT 100;