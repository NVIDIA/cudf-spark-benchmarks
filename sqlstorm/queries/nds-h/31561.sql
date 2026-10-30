
WITH  ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
),
supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, COALESCE(SUM(co.total_spent), 0) AS total_spending,
       COALESCE(SUM(ss.total_supply_cost), 0) AS total_supply_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer_orders co ON n.n_nationkey = co.c_custkey
LEFT JOIN supplier_summary ss ON ss.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE EXISTS (
        SELECT 1 FROM lineitem l
        WHERE l.l_partkey = ps.ps_partkey
        AND l.l_orderkey IN (SELECT o_orderkey FROM ranked_orders WHERE rank = 1)
    )
)
GROUP BY r.r_name
HAVING COALESCE(SUM(co.total_spent), 0) > 10000
ORDER BY total_supply_cost DESC, r.r_name ASC;
