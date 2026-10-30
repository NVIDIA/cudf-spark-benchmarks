WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_availqty) AS total_available_qty, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
)

SELECT ns.n_name, ns.supplier_count, ns.customer_count, 
       SUM(sp.total_available_qty) AS total_parts_available,
       SUM(sp.total_supply_cost) AS total_supply_value,
       SUM(co.order_count) AS total_orders,
       SUM(co.total_spent) AS total_revenue
FROM NationSummary ns
LEFT JOIN SupplierParts sp ON ns.n_nationkey = sp.s_nationkey
LEFT JOIN CustomerOrders co ON ns.n_nationkey = co.c_custkey
GROUP BY ns.n_name, ns.supplier_count, ns.customer_count
ORDER BY ns.n_name;
