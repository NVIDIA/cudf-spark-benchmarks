WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 100000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal < sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
)
SELECT p.p_partkey, 
       p.p_name, 
       SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) AS total_revenue,
       ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
       STRING_AGG(DISTINCT CONCAT(n.n_name, ': ', s.s_name), '; ') AS supplier_info
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE p.p_retailprice BETWEEN 10.00 AND 100.00
AND EXISTS (
    SELECT 1 
    FROM CustomerOrders co 
    WHERE co.c_custkey IN (SELECT o.o_custkey 
                           FROM orders o 
                           WHERE o.o_orderstatus = 'O')
    AND co.total_spent > 5000
)
GROUP BY p.p_partkey, p.p_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 2000
ORDER BY total_revenue DESC
LIMIT 10 OFFSET 10;
