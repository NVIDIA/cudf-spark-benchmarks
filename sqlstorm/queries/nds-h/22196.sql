
WITH  TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_availqty, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) * 1.5 FROM supplier)
),
BestCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationSummary AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
PartPriceAnalysis AS (
    SELECT p.p_partkey, AVG(l.l_extendedprice) AS avg_price,
           CASE 
               WHEN COUNT(l.l_orderkey) > 10 THEN 'High Demand'
               WHEN COUNT(l.l_orderkey) BETWEEN 5 AND 10 THEN 'Medium Demand'
               ELSE 'Low Demand' 
           END AS demand_category
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey
)
SELECT ns.n_name, COUNT(tc.s_suppkey) AS active_suppliers,
       SUM(bc.total_spent) AS total_sales,
       pp.avg_price, pp.demand_category
FROM NationSummary ns
LEFT JOIN TopSuppliers tc ON ns.supplier_count > 0
LEFT JOIN BestCustomers bc ON ns.supplier_count > 0 AND ns.supplier_count = bc.rank
LEFT JOIN PartPriceAnalysis pp ON pp.avg_price = 
    (SELECT MAX(avg_price) FROM PartPriceAnalysis WHERE demand_category = 'High Demand')
WHERE ns.total_acctbal IS NOT NULL
GROUP BY ns.n_name, pp.avg_price, pp.demand_category
HAVING SUM(bc.total_spent) IS NOT NULL AND COUNT(tc.s_suppkey) > 2
ORDER BY total_sales DESC, ns.n_name ASC
LIMIT 10;
