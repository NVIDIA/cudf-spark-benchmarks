
WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_brand, p_size, p_retailprice,
           COALESCE(NULLIF(p_comment, ''), 'No comment available') AS p_comment,
           1 AS level
    FROM part
    WHERE p_size > 20

    UNION ALL

    SELECT p.p_partkey, CONCAT(ph.p_name, ' -> ', p.p_name), p.p_brand, p.p_size, p.p_retailprice,
           COALESCE(NULLIF(p.p_comment, ''), 'No comment available') AS p_comment,
           ph.level + 1
    FROM part p
    JOIN part_hierarchy ph ON p.p_size = ph.p_size + 10
)

SELECT r.r_name, n.n_name, s.s_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returns,
       ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON l.l_partkey = ps.ps_partkey
WHERE l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
  AND ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp WHERE ps_availqty > 100)
GROUP BY r.r_name, n.n_name, s.s_name, r.r_regionkey
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL 
   AND SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) IS NOT NULL
ORDER BY revenue_rank
LIMIT 10;
