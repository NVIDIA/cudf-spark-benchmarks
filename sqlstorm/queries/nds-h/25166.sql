
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    LENGTH(p.p_name) AS name_length,
    STRING_AGG(CONCAT(s.s_name, ' (', s.s_address, ')'), ', ') AS suppliers_info,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    AVG(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice ELSE NULL END) AS avg_fulfilled_price
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_comment, ps.ps_suppkey, l.l_quantity, l.l_extendedprice, o.o_orderstatus
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5 AND 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_returned_quantity DESC, avg_fulfilled_price ASC
LIMIT 20;
