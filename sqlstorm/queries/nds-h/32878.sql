
WITH  OrderDates AS (
    SELECT o_orderkey, o_orderdate, ROW_NUMBER() OVER (ORDER BY o_orderdate) AS rn
    FROM orders
    WHERE o_orderdate >= DATE '1995-01-01'
),
SupplierMetrics AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost) AS total_cost, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerSummary AS (
    SELECT c.c_nationkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_brand = 'BrandX')
)
SELECT r.r_name, 
       COALESCE(SUM(CASE WHEN lm.l_returnflag = 'R' THEN lm.l_extendedprice * (1 - lm.l_discount) ELSE 0 END), 0) AS total_returns,
       MAX(cs.total_spent) AS max_spent,
       MIN(cost.total_cost) AS min_supplier_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN CustomerSummary cs ON n.n_nationkey = cs.c_nationkey
LEFT JOIN lineitem lm ON lm.l_orderkey IN (SELECT o_orderkey FROM OrderDates WHERE rn <= 10)
LEFT JOIN SupplierMetrics cost ON lm.l_suppkey = cost.s_suppkey
LEFT JOIN PartDetails pd ON lm.l_partkey = pd.p_partkey AND pd.rn = 1
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING SUM(lm.l_quantity) > 100
ORDER BY total_returns DESC, max_spent DESC;
