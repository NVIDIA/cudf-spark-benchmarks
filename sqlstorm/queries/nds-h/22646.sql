
WITH ranked_orders AS (
    SELECT o.o_orderkey,
           o.o_custkey,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderstatus IN ('O', 'F')
), 
customer_summary AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_totalprice IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
), 
supplier_part_summary AS (
    SELECT s.s_suppkey,
           SUM(ps.ps_availqty) AS total_avail_qty,
           COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied,
           s.s_name
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
    GROUP BY s.s_suppkey, s.s_name
)
SELECT DISTINCT r.r_name,
                COALESCE(SUM(cs.order_count), 0) AS total_orders,
                COALESCE(SUM(cs.total_spent), 0) AS total_spent_all_customers,
                COALESCE(MAX(sp.total_avail_qty), 0) AS max_supplier_avail_qty,
                ARRAY_AGG(DISTINCT sp.s_name) AS suppliers_names,
                COUNT(DISTINCT n.n_nationkey) FILTER (WHERE n.n_comment IS NULL) AS nations_null_comments
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer_summary cs ON n.n_nationkey = cs.c_custkey
LEFT JOIN ranked_orders o ON cs.c_custkey = o.o_custkey
LEFT JOIN supplier_part_summary sp ON sp.s_suppkey = (SELECT ps.ps_suppkey 
                                                       FROM partsupp ps 
                                                       WHERE ps.ps_partkey IN (SELECT DISTINCT p2.p_partkey 
                                                                               FROM part p2 
                                                                               WHERE p2.p_size < 20) 
                                                       LIMIT 1)
GROUP BY r.r_name
HAVING COALESCE(SUM(cs.total_spent), 0) > 10000
ORDER BY r.r_name;
