SELECT p.p_name, 
       s.s_name, 
       c.c_name, 
       COUNT(DISTINCT o.o_orderkey) AS order_count, 
       SUM(l.l_quantity) AS total_quantity, 
       AVG(l.l_extendedprice) AS avg_price, 
       MAX(l.l_shipdate) AS last_ship_date, 
       CONCAT('Supplied by ', s.s_name, ' in ', r.r_name) AS supply_info
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_comment LIKE '%cotton%' 
  AND n.n_name IN ('USA', 'Canada')
  AND o.o_orderdate BETWEEN '1996-01-01' AND '1997-12-31'
GROUP BY p.p_name, s.s_name, c.c_name, r.r_name
HAVING SUM(l.l_quantity) > 100
ORDER BY total_quantity DESC, avg_price ASC;