
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.level * 1000
), 

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
), 

HighValueOrders AS (
    SELECT co.*, (co.o_totalprice * 0.9) AS discounted_price
    FROM CustomerOrders co
    WHERE co.order_rank <= 5
)

SELECT 
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    AVG(l.l_extendedprice) AS avg_ext_price,
    SUM(l.l_extendedprice * (1 - COALESCE(l.l_discount, 0))) AS total_revenue,
    COALESCE(NULLIF(AVG(s.s_acctbal), 0), 1) AS avg_supplier_account_balance
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
WHERE p.p_size BETWEEN 10 AND 50 
  AND (p.p_retailprice > 20 OR p.p_comment LIKE '%premium%')
GROUP BY p.p_name
HAVING COUNT(DISTINCT l.l_orderkey) > 0
ORDER BY total_revenue DESC
LIMIT 10;
