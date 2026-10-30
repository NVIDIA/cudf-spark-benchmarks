SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    l.l_shipdate AS ship_date,
    REGEXP_REPLACE(CONCAT(c.c_address, ' ', s.s_address), '\\s+', ' ') AS combined_address,
    COUNT(*) OVER (PARTITION BY c.c_nationkey) AS nation_count,
    LENGTH(l.l_comment) AS comment_length,
    LOWER(REPLACE(p.p_comment, ' ', '_')) AS sanitized_comment
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
    s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
ORDER BY 
    ship_date DESC, part_name;