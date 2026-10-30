WITH  order_totals AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
), ranked_orders AS (
    SELECT ot.*, 
           RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM order_totals ot
), parts_summary AS (
    SELECT p.p_partkey, 
           p.p_name,
           SUM(l.l_quantity) AS total_quantity,
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), nation_supplier AS (
    SELECT n.n_nationkey, 
           n.n_name, 
           COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT ro.rank, 
       ro.c_name, 
       ps.p_name, 
       ps.total_quantity, 
       ps.avg_supplycost,
       ns.n_name,
       CASE 
           WHEN ps.total_quantity IS NULL THEN 'No Sales' 
           ELSE 'Has Sales' 
       END AS sales_status
FROM ranked_orders ro
JOIN parts_summary ps ON ro.c_custkey = ps.p_partkey
LEFT JOIN nation_supplier ns ON ns.n_nationkey = ro.c_custkey
WHERE ns.supplier_count > 0
ORDER BY ro.rank, ps.total_quantity DESC
LIMIT 50;
