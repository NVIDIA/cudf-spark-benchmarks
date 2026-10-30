
WITH  OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS rn
    FROM orders
    WHERE o_orderdate < DATE '1998-10-01' AND o_totalprice IS NOT NULL
),
SupplierStats AS (
    SELECT s_nationkey, COUNT(DISTINCT s_suppkey) AS supplier_count,
           SUM(s_acctbal) AS total_acctbal
    FROM supplier
    GROUP BY s_nationkey
),
PartDetails AS (
    SELECT p_partkey, p_name, p_size, p_retailprice,
           (SELECT MAX(ps_supplycost) FROM partsupp WHERE ps_partkey = p_partkey) AS max_supply_cost
    FROM part
    WHERE p_retailprice > 100
    UNION ALL
    SELECT DISTINCT ps_partkey, p_name, p_size, p_retailprice,
           0 AS max_supply_cost
    FROM part
    LEFT JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
    WHERE partsupp.ps_partkey IS NULL
)
SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       AVG(COALESCE(ps_total_order_value, 0)) AS avg_order_value,
       MAX(p.p_retailprice) AS highest_retail_price,
       LEAST(100, MAX(s.supplier_count)) AS capped_supplier_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN (SELECT oh.o_orderkey, SUM(oh.o_totalprice) AS ps_total_order_value
           FROM OrderHierarchy oh
           GROUP BY oh.o_orderkey) ps ON c.c_custkey = ps.o_orderkey
JOIN lineitem l ON c.c_custkey = l.l_orderkey
JOIN PartDetails p ON l.l_partkey = p.p_partkey
LEFT JOIN SupplierStats s ON n.n_nationkey = s.s_nationkey
WHERE l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1997-10-31'
  AND (p.max_supply_cost IS NULL OR p.max_supply_cost > 50)
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 0 AND MAX(p.p_retailprice) IS NOT NULL
ORDER BY total_revenue DESC, r.r_name ASC;
