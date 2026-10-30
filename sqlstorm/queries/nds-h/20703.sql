WITH  CustomerRank AS (
    SELECT c_custkey, c_name, c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c_nationkey ORDER BY c_acctbal DESC) AS rnk
    FROM customer
    WHERE c_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT p_partkey, p_name, p_brand, p_retailprice,
           CASE 
               WHEN p_retailprice <= 100 THEN 'LOW'
               WHEN p_retailprice BETWEEN 100 AND 500 THEN 'MEDIUM'
               ELSE 'HIGH'
           END AS price_category
    FROM part
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
    ORDER BY total_supply_cost DESC
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice,
           COUNT(l.l_orderkey) AS total_line_items,
           SUM(l.l_discount) AS total_discount,
           AVG(l.l_extendedprice) AS avg_data
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
    HAVING SUM(l.l_quantity) > 100
)
SELECT cr.c_name AS customer_name, 
       hp.p_name AS part_name, 
       sd.s_name AS supplier_name,
       os.total_line_items,
       os.total_discount,
       COUNT(*) OVER (PARTITION BY hp.price_category) AS parts_count,
       DENSE_RANK() OVER (PARTITION BY hp.price_category ORDER BY os.total_discount DESC) AS discount_rank
FROM CustomerRank cr
FULL OUTER JOIN HighValueParts hp ON cr.rnk = 1
INNER JOIN SupplierDetails sd ON hp.p_partkey = sd.s_nationkey
LEFT JOIN OrderSummary os ON cr.c_custkey = os.o_orderkey
WHERE (cr.rnk IS NOT NULL OR sd.s_name IS NOT NULL)
  AND (hp.p_retailprice IS NOT NULL AND hp.p_retailprice > 0)
ORDER BY cr.c_name, hp.price_category, os.total_discount DESC;
