SELECT 
    SUBSTRING(p.p_name, 1, 20) AS short_name,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    AVG(l.l_extendedprice) AS avg_extended_price,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    MAX(CASE WHEN c.c_mktsegment = 'BUILDING' THEN s.s_acctbal ELSE NULL END) AS max_building_segment_acctbal,
    RANK() OVER (ORDER BY SUM(l.l_extendedprice) DESC) AS price_rank
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 100.00
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND c.c_comment NOT LIKE '%not interested%'
GROUP BY 
    SUBSTRING(p.p_name, 1, 20)
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    price_rank;