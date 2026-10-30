WITH SupplierStats AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
OrderStats AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
        COALESCE(os.total_orders, 0) AS total_orders,
        COALESCE(os.avg_order_value, 0) AS avg_order_value
    FROM nation n
    LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_nationkey
    LEFT JOIN OrderStats os ON n.n_nationkey = os.c_nationkey
)
SELECT 
    ns.n_name,
    ns.total_supply_cost,
    ns.total_orders,
    ns.avg_order_value,
    CASE 
        WHEN ns.total_supply_cost > 0 AND ns.total_orders > 0 THEN 
            (ns.total_supply_cost / ns.total_orders)
        ELSE 
            NULL 
    END AS cost_per_order
FROM NationStats ns
ORDER BY ns.total_orders DESC, ns.total_supply_cost DESC
LIMIT 10;
