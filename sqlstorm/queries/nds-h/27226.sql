SELECT p.p_name, 
       COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
       SUM(l.l_quantity) AS total_quantity, 
       AVG(CASE 
               WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) 
               ELSE l.l_extendedprice 
           END) AS avg_price_after_discount, 
       r.r_name AS region_name
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
GROUP BY p.p_name, r.r_name
HAVING COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY total_quantity DESC, avg_price_after_discount ASC;