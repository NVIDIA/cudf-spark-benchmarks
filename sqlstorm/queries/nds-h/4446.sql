WITH TotalSupplierCost AS (
    SELECT ps_partkey, SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM partsupp
    GROUP BY ps_partkey
), 
HighValueCustomers AS (
    SELECT c_custkey, c_name, c_acctbal, ROW_NUMBER() OVER (ORDER BY c_acctbal DESC) AS rank
    FROM customer
    WHERE c_acctbal IS NOT NULL AND c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name,
    n.n_name,
    COALESCE(SUM(t.total_cost), 0) AS total_cost,
    COALESCE(SUM(o.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS active_customers,
    CASE 
        WHEN COALESCE(SUM(o.total_revenue), 0) > 0 THEN 'Profitable'
        ELSE 'Unprofitable'
    END AS business_status
FROM region r
LEFT OUTER JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN TotalSupplierCost t ON ps.ps_partkey = t.ps_partkey
LEFT JOIN OrderSummary o ON s.s_suppkey = o.o_orderkey
LEFT JOIN HighValueCustomers c ON c.c_custkey = s.s_suppkey
GROUP BY r.r_name, n.n_name
HAVING COALESCE(SUM(t.total_cost), 0) > 100000 OR COUNT(DISTINCT c.c_custkey) > 10
ORDER BY total_cost DESC, total_revenue DESC;
