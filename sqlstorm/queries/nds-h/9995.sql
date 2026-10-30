WITH ranked_nations AS (
    SELECT n.n_name, n.n_regionkey, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, n.n_regionkey
),
total_parts AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
order_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS customer_total
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT rn.n_name AS nation_name,
       COUNT(DISTINCT os.c_custkey) AS total_customers,
       SUM(tp.total_available) AS total_parts_available,
       AVG(os.customer_total) AS avg_customer_spending
FROM ranked_nations rn
JOIN total_parts tp ON rn.supplier_count > 10
JOIN order_summary os ON rn.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'Asia')
WHERE rn.supplier_count IS NOT NULL
GROUP BY rn.n_name
ORDER BY total_customers DESC, avg_customer_spending DESC
LIMIT 10;
