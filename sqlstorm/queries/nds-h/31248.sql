WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TopSuppliers AS (
    SELECT s_nationkey, SUM(s_acctbal) AS total_acctbal
    FROM supplier
    GROUP BY s_nationkey
    HAVING SUM(s_acctbal) > 5000
),
PartSupply AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, p.p_type
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT n.n_name, SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_revenue,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       SUM(CASE WHEN l.l_tax IS NULL THEN 0 ELSE l.l_tax END) AS total_tax,
       STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
JOIN orders o ON o.o_custkey = s.s_suppkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN PartSupply ps ON l.l_partkey = ps.ps_partkey
WHERE n.n_comment IS NOT NULL
AND ps.ps_availqty > 0
GROUP BY n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_revenue DESC
LIMIT 5;
