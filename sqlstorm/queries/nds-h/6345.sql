WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
OrderLineStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue, COUNT(l.l_orderkey) AS total_lines
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_avail_qty, ss.avg_supply_cost
    FROM SupplierStats ss
    JOIN supplier s ON s.s_suppkey = ss.s_suppkey
    ORDER BY ss.total_avail_qty DESC
    LIMIT 5
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, cs.total_orders, cs.total_spent
    FROM CustomerStats cs
    JOIN customer c ON c.c_custkey = cs.c_custkey
    ORDER BY cs.total_spent DESC
    LIMIT 5
),
OrdersWithRevenue AS (
    SELECT o.o_orderkey, ol.net_revenue, ol.total_lines
    FROM OrderLineStats ol
    JOIN orders o ON ol.o_orderkey = o.o_orderkey
)
SELECT ts.s_name AS supplier_name, 
       tc.c_name AS customer_name, 
       owr.net_revenue, 
       owr.total_lines, 
       ts.total_avail_qty, 
       ts.avg_supply_cost
FROM TopSuppliers ts
JOIN TopCustomers tc ON tc.total_spent > 1000
JOIN OrdersWithRevenue owr ON owr.net_revenue > 5000
WHERE ts.avg_supply_cost < 50
ORDER BY ts.total_avail_qty DESC, owr.net_revenue DESC;
