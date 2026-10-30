WITH SupplierCost AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
OrderLineStats AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.r_name, COUNT(DISTINCT o.o_orderkey) AS order_count, AVG(c.total_spent) AS avg_spent_per_customer, SUM(sc.total_supply_cost) AS total_supply_costs
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN SupplierCost sc ON s.s_suppkey = sc.s_suppkey
JOIN CustomerOrders c ON s.s_suppkey = c.c_custkey
JOIN orders o ON o.o_custkey = c.c_custkey
JOIN OrderLineStats ol ON o.o_orderkey = ol.l_orderkey
WHERE c.total_orders > 5 AND sc.total_supply_cost > 1000
GROUP BY r.r_name
HAVING SUM(ol.total_sales) > 5000
ORDER BY order_count DESC, avg_spent_per_customer DESC;
