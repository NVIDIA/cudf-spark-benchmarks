WITH  supplier_rank AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
), max_order_price AS (
    SELECT o.o_custkey,
           MAX(o.o_totalprice) AS max_price
    FROM orders o
    GROUP BY o.o_custkey
), customer_orders AS (
    SELECT c.c_custkey,
           c.c_name,
           MAX(o.o_orderdate) AS last_order_date,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), discounted_lineitems AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
), supplier_details AS (
    SELECT ps.ps_partkey,
           ps.ps_suppkey,
           p.p_brand,
           p.p_size,
           s.s_name,
           s.s_acctbal,
           COALESCE(NULLIF(s.s_comment, ''), 'No comment') AS safe_comment
    FROM partsupp ps
    JOIN part p ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE p.p_size < 20
),
final_report AS (
    SELECT co.c_custkey,
           co.c_name,
           co.order_count,
           sr.s_name AS top_supplier,
           sr.rank,
           moc.max_price,
           dl.revenue
    FROM customer_orders co
    LEFT JOIN max_order_price moc ON co.c_custkey = moc.o_custkey
    LEFT JOIN supplier_rank sr ON sr.rank = 1
    LEFT JOIN discounted_lineitems dl ON dl.l_orderkey = co.c_custkey
    WHERE co.order_count > 5 AND
          (moc.max_price IS NOT NULL OR dl.revenue > 1000)
)
SELECT DISTINCT f.c_custkey,
                f.c_name,
                f.order_count,
                f.top_supplier,
                f.max_price,
                f.revenue
FROM final_report f
WHERE f.revenue IS NOT NULL
ORDER BY f.c_custkey DESC, f.max_price ASC NULLS LAST;
