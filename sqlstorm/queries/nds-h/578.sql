WITH  supplier_totals AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
best_selling_parts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS total_sold
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_quantity) > 100
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING AVG(o.o_totalprice) IS NOT NULL
),
nation_revenue AS (
    SELECT n.n_nationkey, n.n_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    COALESCE(st.total_cost, 0) AS supplier_total_cost,
    COALESCE(bsp.total_sold, 0) AS best_selling_part_quantity,
    COALESCE(cus.avg_order_value, 0) AS avg_order_value,
    COALESCE(nr.total_revenue, 0) AS total_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_totals st ON n.n_nationkey = st.s_suppkey 
LEFT JOIN best_selling_parts bsp ON st.s_suppkey = bsp.p_partkey 
LEFT JOIN customer_order_summary cus ON cus.c_custkey = st.s_suppkey
LEFT JOIN nation_revenue nr ON n.n_nationkey = nr.n_nationkey
WHERE (st.total_cost IS NOT NULL OR bsp.total_sold > 50)
ORDER BY r.r_name, nation_name;
