SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    p.p_size,
    p.p_container,
    p.p_retailprice,
    p.p_comment,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    LENGTH(p.p_comment) AS comment_length,
    CONCAT('Processed: ', p.p_name, ' (', p.p_brand, ')') AS processed_info
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
    p.p_retailprice > 100.00 
    AND s.s_acctbal > 500.00
    AND o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, 
    p.p_container, p.p_retailprice, p.p_comment, s.s_name, c.c_name
ORDER BY 
    total_quantity DESC, avg_extended_price DESC
LIMIT 50;