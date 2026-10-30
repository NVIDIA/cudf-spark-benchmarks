WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
CustomerSummary AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierTotals AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT r.r_name,
       COUNT(DISTINCT c.c_custkey) AS num_customers,
       AVG(cs.total_spent) AS avg_customer_spending,
       SUM(CASE WHEN lo.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returns_count,
       SUM(CASE WHEN so.total_supply_cost IS NULL THEN 0 ELSE so.total_supply_cost END) AS total_costs
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN CustomerSummary cs ON c.c_custkey = cs.c_custkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem lo ON o.o_orderkey = lo.l_orderkey
LEFT JOIN SupplierTotals so ON lo.l_suppkey = so.s_suppkey
WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
GROUP BY r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY avg_customer_spending DESC;