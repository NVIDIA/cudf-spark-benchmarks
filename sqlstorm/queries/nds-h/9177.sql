WITH SupplierAgg AS (
    SELECT s_nationkey, SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM supplier
    JOIN partsupp ON s_suppkey = ps_suppkey
    GROUP BY s_nationkey
),
CustomerOrders AS (
    SELECT c_nationkey, COUNT(o_orderkey) AS order_count, SUM(o_totalprice) AS total_revenue
    FROM customer
    JOIN orders ON c_custkey = o_custkey
    GROUP BY c_nationkey
)
SELECT r.r_name AS region_name,
       n.n_name AS nation_name,
       COALESCE(c.order_count, 0) AS total_orders,
       COALESCE(c.total_revenue, 0) AS total_revenue,
       COALESCE(s.total_cost, 0) AS total_supplier_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN CustomerOrders c ON n.n_nationkey = c.c_nationkey
LEFT JOIN SupplierAgg s ON n.n_nationkey = s.s_nationkey
WHERE r.r_name = 'ASIA'
ORDER BY total_orders DESC, total_supplier_cost DESC;
