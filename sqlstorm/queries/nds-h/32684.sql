WITH  SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS cost_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 0
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.total_spent,
           RANK() OVER (ORDER BY c.total_spent DESC) AS spending_rank
    FROM CustomerOrders c
), RegionSupplier AS (
    SELECT n.n_regionkey, r.r_name,
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_regionkey, r.r_name
)
SELECT r.r_name, 
       COUNT(DISTINCT sp.s_suppkey) AS supplier_count,
       COALESCE(SUM(sp.ps_supplycost), 0) AS total_supplycost,
       COUNT(DISTINCT tc.c_custkey) AS top_customer_count,
       AVG(sp.s_acctbal) AS avg_acctbal
FROM RegionSupplier r
LEFT JOIN SupplierPerformance sp ON r.total_acctbal > 0
LEFT JOIN TopCustomers tc ON sp.s_suppkey = tc.c_custkey
WHERE r.total_acctbal IS NOT NULL
GROUP BY r.r_name
HAVING AVG(sp.s_acctbal) > 1000
ORDER BY total_supplycost DESC, supplier_count ASC;
