WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_available_quantity,
        ss.unique_parts_supplied,
        ss.avg_supply_cost,
        RANK() OVER (ORDER BY ss.total_available_quantity DESC) AS rnk
    FROM supplier_summary ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
top_customers AS (
    SELECT 
        cus.c_custkey,
        cus.c_name,
        cos.total_orders,
        cos.total_spent,
        RANK() OVER (ORDER BY cos.total_spent DESC) AS rnk
    FROM customer_order_summary cos
    JOIN customer cus ON cos.c_custkey = cus.c_custkey
)
SELECT 
    ts.s_name AS supplier_name,
    tc.c_name AS customer_name,
    ts.total_available_quantity,
    ts.unique_parts_supplied,
    ts.avg_supply_cost,
    tc.total_orders,
    tc.total_spent
FROM top_suppliers ts
JOIN top_customers tc ON ts.rnk = 1 AND tc.rnk <= 5
ORDER BY ts.total_available_quantity DESC, tc.total_spent DESC;
