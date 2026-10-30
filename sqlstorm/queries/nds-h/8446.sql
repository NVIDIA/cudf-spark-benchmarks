WITH supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F' 
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    cs.c_name,
    sd.s_name,
    sd.total_cost,
    cs.order_count,
    cs.total_spent,
    ns.supplier_count
FROM customer_order_summary cs
JOIN supplier_details sd ON cs.c_nationkey = sd.s_nationkey
JOIN nation_summary ns ON cs.c_nationkey = ns.n_nationkey
WHERE sd.total_cost > 100000 
ORDER BY cs.total_spent DESC, sd.total_cost DESC
LIMIT 10;