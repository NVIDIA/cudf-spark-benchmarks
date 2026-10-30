WITH SupplierCost AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM partsupp ps
),
TopSuppliers AS (
    SELECT sc.ps_partkey, s.s_name, sc.ps_supplycost, sc.ps_availqty
    FROM SupplierCost sc
    JOIN supplier s ON sc.ps_suppkey = s.s_suppkey
    WHERE sc.rn = 1
),
OrdersSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS num_customers,
       SUM(ts.ps_availqty) AS total_available,
       AVG(ts.ps_supplycost) AS avg_supply_cost,
       COUNT(DISTINCT os.o_orderkey) AS num_orders,
       MAX(os.total_revenue) AS max_revenue,
       CASE WHEN SUM(ts.ps_supplycost) IS NULL THEN 'No Cost Data' ELSE 'Cost Data Available' END AS cost_data_status
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN TopSuppliers ts ON c.c_custkey = ts.ps_partkey
LEFT JOIN OrdersSummary os ON c.c_custkey = os.o_orderkey
WHERE r.r_name LIKE 'N%' AND c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_mktsegment = 'BUILDING')
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY r.r_name DESC;
