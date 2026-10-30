WITH SupplierAvailability AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_availqty) AS total_available_qty,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerRanked AS (
    SELECT c.c_custkey, 
           c.c_name, 
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS account_rank
    FROM customer c
)
SELECT n.n_name, 
       SUM(od.total_order_value) AS total_revenue,
       COALESCE(SUM(sa.total_available_qty), 0) AS total_available_from_suppliers,
       COUNT(DISTINCT cr.c_custkey) AS distinct_high_value_customers
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierAvailability sa ON s.s_suppkey = sa.s_suppkey
LEFT JOIN OrderDetails od ON s.s_suppkey = od.o_orderkey
LEFT JOIN CustomerRanked cr ON od.o_orderkey = cr.c_custkey
WHERE n.n_name IS NOT NULL 
AND sa.total_available_qty < 1000
AND cr.account_rank = 1
GROUP BY n.n_name
ORDER BY total_revenue DESC
LIMIT 10;
