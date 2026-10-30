WITH region_orders AS (
    SELECT r.r_name, COUNT(o.o_orderkey) AS order_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON l.l_partkey = p.p_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_name
)
SELECT r_name, order_count
FROM region_orders
ORDER BY order_count DESC
LIMIT 10;
