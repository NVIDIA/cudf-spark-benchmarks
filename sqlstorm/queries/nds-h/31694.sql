
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer) 

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'Universities%')
    WHERE ch.level < 5
)

SELECT
    p.p_partkey,
    p.p_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS revenue_rank
FROM part p
LEFT JOIN lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE COALESCE(c.c_acctbal, 0) > 5000 
  AND r.r_name IN ('Africa', 'Asia') 
  AND p.p_size BETWEEN 10 AND 20
GROUP BY p.p_partkey, p.p_name
HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > (SELECT AVG(total_revenue) FROM (
    SELECT SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem li ON p.p_partkey = li.l_partkey
    JOIN orders o ON li.l_orderkey = o.o_orderkey
    GROUP BY p.p_partkey
) AS avg_revenue)
ORDER BY total_revenue DESC
LIMIT 10
;