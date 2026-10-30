WITH  top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY ps.ps_supplycost DESC) as rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey
),
frequent_customers AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
)
SELECT r.r_name, 
       COALESCE(SUM(co.total_spent), 0) AS total_revenue,
       COUNT(DISTINCT fc.c_custkey) AS frequent_buyers,
       COUNT(DISTINCT ts.s_suppkey) AS top_suppliers_count
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer_orders co ON n.n_nationkey = co.c_custkey
LEFT JOIN frequent_customers fc ON co.c_custkey = fc.c_custkey
LEFT JOIN top_suppliers ts ON n.n_nationkey = ts.s_suppkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
ORDER BY total_revenue DESC
LIMIT 10;
