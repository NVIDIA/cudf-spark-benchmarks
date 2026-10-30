WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_mktsegment, 1 AS level
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, oh.c_mktsegment, oh.level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON oh.o_orderkey = o.o_orderkey
    WHERE oh.level < 5
)

SELECT 
    p.p_partkey,
    p.p_name,
    SUM(COALESCE(lp.l_extendedprice * (1 - lp.l_discount), 0)) AS total_sales,
    AVG(CASE WHEN p.p_size IS NULL THEN 0 ELSE p.p_size END) AS avg_size,
    ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY SUM(lp.l_extendedprice * (1 - lp.l_discount)) DESC) AS rank,
    RANK() OVER (ORDER BY SUM(lp.l_extendedprice * (1 - lp.l_discount)) DESC) AS overall_rank,
    (SELECT COUNT(DISTINCT c.c_custkey) 
     FROM customer c 
     WHERE c.c_mktsegment LIKE 'AUTOMOBILE%' AND c.c_acctbal IS NOT NULL) AS automobile_customers
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem lp ON lp.l_partkey = p.p_partkey
LEFT JOIN orders o ON lp.l_orderkey = o.o_orderkey
WHERE (o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1998-01-01' OR p.p_comment IS NULL)
  AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) 
                          FROM part p2 WHERE p2.p_type = p.p_type)
  AND EXISTS (SELECT 1 FROM region r 
              JOIN nation n ON r.r_regionkey = n.n_regionkey 
              WHERE n.n_nationkey = s.s_nationkey AND r.r_name LIKE '%North%')
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_size
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_sales DESC, rank
LIMIT 100;