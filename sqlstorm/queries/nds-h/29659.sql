
SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(s.s_acctbal) AS avg_supplier_balance, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END) AS max_returned_price,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT(s.s_name, ' (', s.s_phone, ')') AS supplier_info
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE p.p_size > 10 
AND l.l_shipdate BETWEEN '1995-01-01' AND '1995-12-31' 
AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_name, 
    s.s_name, 
    s.s_phone, 
    p.p_comment
HAVING SUM(l.l_quantity) > 1000
ORDER BY total_quantity DESC;
