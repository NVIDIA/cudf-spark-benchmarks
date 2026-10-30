
WITH NationSupplier AS (
    SELECT n.n_name, s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplier_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name, s.s_suppkey
),
RegionCost AS (
    SELECT r.r_name, SUM(ns.total_supplier_cost) AS total_region_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN NationSupplier ns ON ns.n_name = n.n_name
    GROUP BY r.r_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT rc.r_name, co.c_name, co.total_order_value, rc.total_region_cost
FROM RegionCost rc
JOIN CustomerOrders co ON rc.total_region_cost > co.total_order_value
WHERE co.total_order_value > 1000
ORDER BY rc.r_name, co.total_order_value DESC;
