
WITH Supplier_Info AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
Customer_Order AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_order_value, c.c_nationkey
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_nationkey
),
Nation_Summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    ns.supplier_count,
    ns.customer_count,
    SUM(ci.total_order_value) AS total_customer_order_value,
    SUM(si.total_cost) AS total_supplier_cost,
    ROUND(SUM(si.total_cost) / NULLIF(SUM(ci.total_order_value), 0), 2) AS cost_to_order_ratio
FROM Nation_Summary ns
LEFT JOIN Customer_Order ci ON ns.n_nationkey = ci.c_nationkey
LEFT JOIN Supplier_Info si ON ns.n_nationkey = si.s_nationkey
GROUP BY ns.n_name, ns.supplier_count, ns.customer_count
ORDER BY ns.n_name;
