SELECT 
    p.p_name,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    REGEXP_REPLACE(s.s_address, '[^a-zA-Z0-9 ]', '') AS cleaned_address,
    o.o_orderdate,
    (l.l_extendedprice * (1 - l.l_discount)) AS net_price,
    CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size > 10 
    AND s.s_acctbal > 1000 
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
ORDER BY 
    net_price DESC
LIMIT 100;