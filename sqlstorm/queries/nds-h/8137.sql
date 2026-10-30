WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.total_revenue) AS total_spent
    FROM customer c
    JOIN ranked_orders ro ON c.c_custkey = ro.o_orderkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT 
    tc.c_name,
    tc.total_spent,
    COUNT(o.o_orderkey) AS order_count,
    MAX(o.o_orderdate) AS last_order_date
FROM top_customers tc
JOIN orders o ON tc.c_custkey = o.o_custkey
GROUP BY tc.c_name, tc.total_spent
ORDER BY total_spent DESC;
