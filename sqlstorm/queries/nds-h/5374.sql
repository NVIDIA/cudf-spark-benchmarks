WITH  order_hierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, 
           o.o_orderpriority, o.o_clerk, o.o_shippriority, COUNT(l.l_orderkey) AS line_item_count
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, 
             o.o_orderpriority, o.o_clerk, o.o_shippriority
),
high_value_orders AS (
    SELECT oh.o_orderkey, oh.o_orderstatus, oh.o_totalprice, oh.o_orderdate, 
           oh.o_orderpriority, oh.o_clerk, oh.line_item_count
    FROM order_hierarchy oh
    WHERE oh.o_totalprice > (SELECT AVG(o_totalprice) FROM order_hierarchy)
    ORDER BY oh.o_totalprice DESC
    LIMIT 10
)
SELECT 
    oh.o_orderkey,
    c.c_name,
    c.c_nationkey,
    n.n_name AS nation_name,
    r.r_name AS region_name,
    oh.o_totalprice,
    oh.o_orderdate,
    oh.line_item_count
FROM high_value_orders oh
JOIN customer c ON c.c_custkey = oh.o_orderkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE oh.o_orderstatus = 'O'
ORDER BY oh.o_totalprice DESC;
