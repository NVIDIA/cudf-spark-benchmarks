SELECT p.p_name, 
       SUM(l.l_quantity) AS total_quantity, 
       AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount, 
       COUNT(DISTINCT o.o_orderkey) AS order_count, 
       c.c_mktsegment 
FROM part p 
JOIN lineitem l ON p.p_partkey = l.l_partkey 
JOIN orders o ON l.l_orderkey = o.o_orderkey 
JOIN customer c ON o.o_custkey = c.c_custkey 
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN nation n ON s.s_nationkey = n.n_nationkey 
JOIN region r ON n.n_regionkey = r.r_regionkey 
WHERE r.r_name LIKE 'Asia%' 
  AND c.c_acctbal > 1000 
  AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY p.p_name, c.c_mktsegment 
HAVING SUM(l.l_quantity) > 100 
ORDER BY total_quantity DESC, avg_price_after_discount;