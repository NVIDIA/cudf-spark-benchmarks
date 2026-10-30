WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available_qty, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT p.p_partkey) AS total_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT o.o_custkey, SUM(l.l_quantity) AS total_ordered_qty,
           AVG(o.o_totalprice) AS avg_order_price,
           COUNT(o.o_orderkey) AS total_orders
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           COALESCE(o.total_ordered_qty, 0) AS total_ordered_qty, 
           COALESCE(o.avg_order_price, 0) AS avg_order_price
    FROM customer c
    LEFT JOIN OrderStats o ON c.c_custkey = o.o_custkey
),
SupplierCustomerStats AS (
    SELECT s.s_name, cs.c_name, cs.c_acctbal, 
           ss.total_parts, ss.total_available_qty, ss.total_supply_cost,
           cs.total_ordered_qty, cs.avg_order_price
    FROM SupplierStats ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN CustomerSummary cs ON cs.total_ordered_qty > 0
)
SELECT s_name, c_name, c_acctbal, total_parts, total_available_qty, 
       total_supply_cost, total_ordered_qty, avg_order_price
FROM SupplierCustomerStats
WHERE total_supply_cost > 1000.00
ORDER BY total_ordered_qty DESC, avg_order_price DESC
LIMIT 10;
