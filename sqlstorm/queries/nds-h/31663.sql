
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_custkey, c.c_name, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000  
    UNION ALL
    SELECT c.c_custkey, c.c_name, ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_nationkey = (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_name LIKE 'A%')  
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(ps.ps_supplycost) AS total_supplycost,
    AVG(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice ELSE NULL END) AS avg_discount_price,
    STRING_AGG(DISTINCT p.p_name) AS part_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
WHERE r.r_name IS NOT NULL 
  AND (l.l_returnflag IS NULL OR l.l_returnflag IN ('A', 'N'))  
  AND l.l_shipdate >= DATE '1996-01-01'
  AND (s.s_acctbal > 500 OR s.s_comment NOT LIKE '%discount%')  
GROUP BY r.r_name
HAVING COUNT(DISTINCT s.s_suppkey) > 5  
ORDER BY nation_count DESC
LIMIT 10;
