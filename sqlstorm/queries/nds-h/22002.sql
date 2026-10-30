WITH  supplier_ranking AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
quantity_distribution AS (
    SELECT l.l_orderkey, SUM(l.l_quantity) AS total_quantity,
           COUNT(DISTINCT l.l_suppkey) AS distinct_suppliers,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY l.l_quantity) AS median_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey
),
order_details AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_mktsegment,
           COALESCE(qd.total_quantity, 0) AS order_quantity,
           COALESCE(qd.distinct_suppliers, 0) AS supplier_count,
           COALESCE(qd.median_quantity, 0) AS order_median_quantity
    FROM orders o
    LEFT JOIN customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN quantity_distribution qd ON o.o_orderkey = qd.l_orderkey
)
SELECT od.o_orderkey,
       od.o_orderdate,
       od.c_mktsegment,
       od.order_quantity,
       od.supplier_count,
       od.order_median_quantity,
       CASE WHEN od.order_quantity > 100 THEN 'High Volume' 
            ELSE 'Low Volume' 
       END AS order_category,
       COUNT(DISTINCT sr.s_suppkey) FILTER (WHERE sr.rank_within_nation <= 3) AS top_suppliers_count,
       MIN(COALESCE(l.l_discount, 0)) AS min_discount,
       MAX(COALESCE(l.l_discount, 0)) AS max_discount
FROM order_details od
LEFT JOIN lineitem l ON od.o_orderkey = l.l_orderkey
LEFT JOIN supplier_ranking sr ON sr.s_suppkey = l.l_suppkey
GROUP BY od.o_orderkey, od.o_orderdate, od.c_mktsegment, od.order_quantity, od.supplier_count, od.order_median_quantity
HAVING COUNT(DISTINCT sr.s_suppkey) FILTER (WHERE sr.rank_within_nation <= 3) > 0
ORDER BY od.o_orderdate DESC NULLS LAST;
