SELECT 
    CONCAT(c.c_name, ' (', n.n_name, ')') AS customer_info,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) END) AS returned_value,
    SUM(CASE WHEN l.l_returnflag = 'N' THEN l.l_extendedprice * (1 - l.l_discount) END) AS non_returned_value,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_quantity) AS average_quantity,
    COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_supplied,
    REGEXP_REPLACE(SUBSTRING(p.p_comment, 1, 25), '[^a-zA-Z0-9 ]', '') AS trimmed_comment,
    REGEXP_REPLACE(SUBSTRING(n.n_comment, 1, 50), '[^a-zA-Z0-9,. ]', '') AS sanitized_nation_comment
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    c.c_name, n.n_name, p.p_comment, n.n_comment
ORDER BY 
    customer_info;