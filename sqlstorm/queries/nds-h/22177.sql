
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), OrdersWithDiscounts AS (
    SELECT o.o_orderkey, o.o_totalprice * (1 - AVG(l.l_discount) OVER (PARTITION BY o.o_orderkey)) AS adjusted_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
), NationStats AS (
    SELECT n.n_nationkey, COUNT(DISTINCT c.c_custkey) AS customer_count,
           SUM(CASE WHEN c.c_acctbal > 0 THEN 1 ELSE 0 END) AS positive_balance_count
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey
)
SELECT rs.rnk, os.o_orderkey, os.adjusted_total, ns.customer_count, ns.positive_balance_count, 
       CASE WHEN ns.customer_count IS NULL THEN 'No Customers' 
            WHEN ns.customer_count > 10 THEN 'Many Customers' 
            ELSE 'Few Customers' END AS customer_category
FROM RankedSuppliers rs
FULL OUTER JOIN OrdersWithDiscounts os ON rs.s_suppkey = os.o_orderkey 
JOIN NationStats ns ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE '%land%' LIMIT 1)
WHERE rs.rnk = 1 AND os.adjusted_total > (SELECT AVG(adjusted_total) FROM OrdersWithDiscounts) 
ORDER BY os.adjusted_total DESC
LIMIT 50;
