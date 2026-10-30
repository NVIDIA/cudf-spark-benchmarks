WITH supplier_totals AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY c.c_custkey, c.c_name
),
nation_supplier AS (
    SELECT n.n_nationkey, 
           n.n_name, 
           COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT n.n_name AS nation_name, 
       COALESCE(SUM(st.total_supply_cost), 0) AS total_supply_cost, 
       COALESCE(SUM(co.total_order_value), 0) AS total_order_value, 
       ns.supplier_count
FROM nation n
LEFT JOIN supplier_totals st ON n.n_nationkey = st.s_suppkey
LEFT JOIN customer_orders co ON n.n_nationkey = co.c_custkey
JOIN nation_supplier ns ON n.n_nationkey = ns.n_nationkey
GROUP BY n.n_name, ns.supplier_count
ORDER BY total_supply_cost DESC, total_order_value DESC;