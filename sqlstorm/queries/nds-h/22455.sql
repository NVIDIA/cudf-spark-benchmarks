
WITH  customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS recent_order
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
), high_value_orders AS (
    SELECT co.c_custkey, SUM(co.o_totalprice) AS total_spent
    FROM customer_orders co
    WHERE co.recent_order <= 5
    GROUP BY co.c_custkey
), supplier_part_info AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty,
           MAX(p.p_retailprice) AS highest_price,
           AVG(p.p_retailprice) AS avg_price,
           STRING_AGG(CASE WHEN p.p_comment IS NULL THEN 'No Comment' ELSE p.p_comment END, ', ') AS comments
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size BETWEEN 10 AND 20
    GROUP BY ps.ps_suppkey
), top_nations AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_balance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING SUM(s.s_acctbal) > 100000
), order_stats AS (
    SELECT o.o_orderstatus, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_price,
           AVG(o.o_totalprice) AS avg_price,
           MAX(o.o_totalprice) AS max_price,
           MIN(o.o_totalprice) AS min_price
    FROM orders o
    GROUP BY o.o_orderstatus
), lineitem_summary AS (
    SELECT l.l_shipdate, COUNT(*) AS lineitem_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipmode IN ('AIR', 'MAIL')
    GROUP BY l.l_shipdate
)

SELECT c.c_name, COALESCE(hv.total_spent, 0) AS total_spent,
       COALESCE(s.total_avail_qty, 0) AS supplier_qty,
       COALESCE(s.highest_price, 0) AS supplier_high_price,
       COALESCE(s.avg_price, 0) AS supplier_avg_price,
       nt.n_name, nt.total_balance,
       os.o_orderstatus AS order_status, os.order_count, os.total_price, os.avg_price, os.max_price, os.min_price,
       ls.lineitem_count, ls.total_revenue
FROM customer c
LEFT JOIN high_value_orders hv ON c.c_custkey = hv.c_custkey
LEFT JOIN supplier_part_info s ON s.ps_suppkey IN (
    SELECT ps.ps_suppkey FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
LEFT JOIN top_nations nt ON c.c_nationkey = nt.n_nationkey
LEFT JOIN order_stats os ON os.o_orderstatus = 'F'
LEFT JOIN lineitem_summary ls ON ls.l_shipdate = DATE '1998-10-01'
WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal BETWEEN 1000 AND 5000
ORDER BY total_spent DESC, nt.total_balance ASC
LIMIT 100;
