WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
FilteredRegions AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name 
    HAVING COUNT(n.n_nationkey) > 0
)
SELECT c.c_name, c.c_acctbal, os.total_spent, os.order_count,
       CASE WHEN fr.nation_count IS NULL THEN 'No Region' ELSE fr.r_name END as region_name,
       CASE WHEN rs.rnk = 1 THEN 'Top Supplier' ELSE 'Other Supplier' END as supplier_rank
FROM customer c
LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
LEFT JOIN RankedSuppliers rs ON c.c_custkey = rs.s_suppkey
LEFT JOIN FilteredRegions fr ON fr.r_regionkey = c.c_nationkey
WHERE c.c_acctbal IS NOT NULL
  AND os.total_spent > (SELECT AVG(total_spent) FROM OrderSummary)
ORDER BY c.c_acctbal DESC, os.total_spent DESC
LIMIT 100;
