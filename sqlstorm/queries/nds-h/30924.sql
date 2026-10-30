WITH  supplier_orders AS (
    SELECT s.s_suppkey, s.s_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY n.n_nationkey, n.n_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT ns.n_name, ns.supplier_count, ns.total_revenue,
       co.c_name AS customer_name, co.order_count, co.total_spent,
       (SELECT AVG(o.o_totalprice) 
        FROM orders o 
        WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31') AS avg_order_value,
       (SELECT COUNT(*) 
        FROM supplier s 
        WHERE s.s_acctbal IS NOT NULL) AS active_suppliers
FROM nation_summary ns
FULL OUTER JOIN customer_orders co ON ns.supplier_count > 5 AND co.total_spent IS NOT NULL
WHERE ns.total_revenue > (SELECT AVG(total_revenue) FROM nation_summary)
ORDER BY ns.total_revenue DESC, co.total_spent DESC;