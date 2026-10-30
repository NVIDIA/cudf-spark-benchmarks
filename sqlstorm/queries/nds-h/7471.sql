WITH SupplierAgg AS (
    SELECT s_nationkey, SUM(ps_supplycost * ps_availqty) AS total_supply_cost
    FROM supplier
    JOIN partsupp ON s_suppkey = ps_suppkey
    GROUP BY s_nationkey
),
CustomerAgg AS (
    SELECT c_nationkey, COUNT(DISTINCT o_orderkey) AS total_orders, SUM(o_totalprice) AS total_revenue
    FROM customer
    JOIN orders ON c_custkey = o_custkey
    GROUP BY c_nationkey
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name, COALESCE(SA.total_supply_cost, 0) AS total_supply_cost, COALESCE(CA.total_orders, 0) AS total_orders, COALESCE(CA.total_revenue, 0) AS total_revenue
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN SupplierAgg SA ON n.n_nationkey = SA.s_nationkey
    LEFT JOIN CustomerAgg CA ON n.n_nationkey = CA.c_nationkey
)
SELECT n.n_name, n.region_name, n.total_supply_cost, n.total_orders, n.total_revenue
FROM NationSummary n
WHERE n.total_supply_cost > 0 AND n.total_orders > 0
ORDER BY n.total_revenue DESC, n.total_supply_cost DESC;
