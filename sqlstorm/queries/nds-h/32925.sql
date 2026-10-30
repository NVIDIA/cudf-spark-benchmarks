
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000
), MaxParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
), CustomerSummary AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 10000
), NationDetails AS (
    SELECT n.n_nationkey, n.n_name, MAX(s.s_acctbal) AS max_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
       COALESCE(c.order_count, 0) AS total_orders,
       rh.total_availqty,
       nd.max_acctbal,
       ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
FROM part p
LEFT JOIN MaxParts rh ON p.p_partkey = rh.ps_partkey
LEFT JOIN CustomerSummary c ON c.c_custkey = (SELECT c1.c_custkey 
                                               FROM customer c1 
                                               WHERE c1.c_name LIKE 'A%' 
                                               LIMIT 1)
LEFT JOIN NationDetails nd ON nd.n_nationkey = p.p_partkey % 10
WHERE p.p_size BETWEEN 10 AND 20
  AND (p.p_comment IS NULL OR p.p_comment NOT LIKE '%damaged%')
ORDER BY p.p_retailprice DESC;
