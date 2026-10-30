
WITH  top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
nation_sales AS (
    SELECT n.n_name, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
),
filtered_line_items AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales
    FROM lineitem l
    WHERE l.l_shipdate > DATE '1997-01-01' AND l.l_discount < 0.05
    GROUP BY l.l_orderkey
)
SELECT n.n_name, ns.order_count, ns.total_sales, COALESCE(fli.net_sales, 0) AS line_item_sales,
       RANK() OVER (ORDER BY ns.total_sales DESC) AS rank
FROM nation_sales ns
JOIN nation n ON ns.n_name = n.n_name
LEFT JOIN filtered_line_items fli ON ns.order_count = (
    SELECT COUNT(*)
    FROM customer_orders co
    WHERE co.o_orderkey IN (SELECT l_orderkey FROM lineitem)
)
ORDER BY rank;
