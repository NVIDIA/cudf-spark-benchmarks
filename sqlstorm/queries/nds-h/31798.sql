WITH  ranked_orders AS (
    SELECT o_orderkey, o_custkey, o_totalprice, o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_totalprice DESC) AS rank
    FROM orders
    WHERE o_orderstatus = 'O'
),
supplier_parts AS (
    SELECT ps_partkey, ps_suppkey, SUM(ps_availqty) AS total_avail
    FROM partsupp
    GROUP BY ps_partkey, ps_suppkey
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN ranked_orders ro ON c.c_custkey = ro.o_custkey
    JOIN orders o ON o.o_orderkey = ro.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, MAX(c.total_spent) AS max_spent
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer_summary c ON c.c_custkey = s.s_suppkey
    GROUP BY n.n_nationkey, n.n_name
),
final_summary AS (
    SELECT ns.n_name AS nation_name, ns.supplier_count, ns.max_spent,
           COUNT(DISTINCT ro.o_orderkey) AS orders_count,
           SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) AS total_revenue
    FROM nation_summary ns
    LEFT JOIN ranked_orders ro ON ns.max_spent = ro.o_totalprice
    LEFT JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
    GROUP BY ns.n_name, ns.supplier_count, ns.max_spent
)
SELECT fs.nation_name, fs.supplier_count, fs.orders_count, fs.total_revenue,
       RANK() OVER (ORDER BY fs.total_revenue DESC) AS revenue_rank
FROM final_summary fs
WHERE fs.total_revenue IS NOT NULL
ORDER BY fs.total_revenue DESC
LIMIT 10;
