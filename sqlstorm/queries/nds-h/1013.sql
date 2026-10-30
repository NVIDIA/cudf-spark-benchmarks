WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           o.o_orderpriority,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),
SuppliersWithParts AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_availqty) AS total_available_qty,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.total_spent,
    r.o_orderkey AS last_order_key,
    r.o_orderdate AS last_order_date,
    r.o_orderpriority AS last_order_priority,
    sp.total_available_qty,
    sp.total_supply_cost,
    COALESCE(rn, 0) AS priority_rank
FROM CustomerOrderSummary co
LEFT JOIN RankedOrders r ON co.total_spent > 1000 AND co.c_custkey = r.o_orderkey
LEFT JOIN SuppliersWithParts sp ON co.total_orders = sp.total_available_qty
WHERE co.total_spent IS NOT NULL AND sp.total_supply_cost > 10000
ORDER BY co.total_spent DESC, sp.total_supply_cost ASC
LIMIT 10;