WITH supplier_stats AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
), 
customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), 
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT n.n_name, 
       r.r_name AS region_name, 
       COUNT(DISTINCT c.c_custkey) AS total_customers,
       SUM(co.order_count) AS total_orders,
       SUM(co.total_spent) AS total_revenue,
       SUM(ss.total_supply_value) AS total_supply_value
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN customer c ON c.c_nationkey = n.n_nationkey
JOIN customer_orders co ON c.c_custkey = co.c_custkey
JOIN supplier_stats ss ON ss.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN part p ON ps.ps_partkey = p.p_partkey 
    WHERE p.p_size > 20
)
GROUP BY n.n_name, r.r_name
ORDER BY total_revenue DESC, total_orders DESC;
