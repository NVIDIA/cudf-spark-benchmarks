
SELECT 
    p.p_name, 
    s.s_name, 
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    MAX(l.l_shipdate) AS last_ship_date,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE 
    s.s_comment LIKE '%reliable%' 
    AND c.c_mktsegment = 'BUILDING'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY p.p_name, s.s_name
HAVING SUM(l.l_quantity) > 100
ORDER BY avg_price_after_discount DESC, unique_customers ASC;
