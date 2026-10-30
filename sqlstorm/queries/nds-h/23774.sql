WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty > 10)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE')
    WHERE s.s_acctbal IS NOT NULL AND sh.level < 5
),
CustomerInfo AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rn
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_acctbal IS NOT NULL)
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
           COUNT(DISTINCT l.l_partkey) AS unique_parts,
           CASE 
               WHEN SUM(l.l_extendedprice * l.l_discount) > 1000 THEN 'High Discount'
               ELSE 'Low Discount'
           END AS discount_category
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING COUNT(DISTINCT l.l_partkey) > 5
),
FilteredSummary AS (
    SELECT os.o_orderkey, os.total_sales, os.unique_parts, ci.c_name, ci.c_acctbal
    FROM OrderSummary os
    JOIN CustomerInfo ci ON os.o_custkey = ci.c_custkey
    WHERE os.total_sales > 500
)

SELECT rh.r_name, COUNT(DISTINCT ps.ps_partkey) AS parts_count,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY f.total_sales) AS median_sales
FROM region rh
LEFT JOIN nation n ON rh.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN FilteredSummary f ON ps.ps_partkey = f.o_orderkey  
GROUP BY rh.r_name
HAVING COUNT(f.total_sales) > (SELECT COUNT(*) / 2 FROM FilteredSummary)
ORDER BY median_sales DESC, rh.r_name
LIMIT 10 OFFSET 0;
