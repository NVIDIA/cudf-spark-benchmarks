WITH order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),

top_customers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(os.total_revenue) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN order_summary os ON o.o_orderkey = os.o_orderkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
)

SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.total_spent,
    COUNT(DISTINCT os.o_orderkey) AS order_count,
    MAX(os.o_orderdate) AS last_order_date
FROM top_customers tc
JOIN orders o ON tc.c_custkey = o.o_custkey
JOIN order_summary os ON o.o_orderkey = os.o_orderkey
GROUP BY tc.c_custkey, tc.c_name, tc.total_spent
ORDER BY total_spent DESC;