WITH  part_availability AS (
    SELECT ps_partkey, ps_suppkey, SUM(ps_availqty) AS total_avail
    FROM partsupp
    GROUP BY ps_partkey, ps_suppkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'P')
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT DISTINCT p.p_name, p.p_brand, COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
       CASE
           WHEN ca.rn IS NOT NULL THEN 'Frequent Buyer'
           ELSE 'Casual Buyer'
       END AS customer_type,
       COUNT(DISTINCT (CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END)) AS returns,
       SUM(CASE WHEN l.l_discount > 0.05 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discounted_sales,
       COUNT(DISTINCT l.l_orderkey) AS total_orders
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN customer_orders ca ON s.s_nationkey = ca.c_custkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
WHERE p.p_retailprice BETWEEN 10.00 AND 100.00
  AND (s.s_acctbal IS NULL OR s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = s.s_nationkey))
GROUP BY p.p_name, p.p_brand, supplier_name, customer_type
HAVING COUNT(DISTINCT l.l_orderkey) >= 5
   OR MAX(CASE WHEN l.l_shipdate > cast('1998-10-01' as date) - INTERVAL '30 days' THEN 1 ELSE 0 END) = 1
ORDER BY discounted_sales DESC, returns ASC NULLS LAST;