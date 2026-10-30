WITH  order_hierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) as recent_order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('F', 'P')
),
supplier_summary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
lineitem_details AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(*) AS item_count,
           AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey
),
popular_parts AS (
    SELECT p.p_partkey, p.p_name, COUNT(li.l_orderkey) AS order_count
    FROM part p
    LEFT JOIN lineitem li ON p.p_partkey = li.l_partkey
    WHERE li.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY p.p_partkey, p.p_name
    HAVING COUNT(li.l_orderkey) > 10
),
customer_nation AS (
    SELECT c.c_custkey, n.n_nationkey, n.n_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
),
result_summary AS (
    SELECT cn.n_name AS nation, 
           oh.o_orderkey, 
           oh.o_orderdate, 
           COALESCE(ls.total_revenue, 0) AS total_revenue, 
           COALESCE(ls.item_count, 0) AS item_count,
           pp.p_name, 
           ps.total_supply_cost
    FROM order_hierarchy oh
    LEFT JOIN lineitem_details ls ON oh.o_orderkey = ls.l_orderkey
    JOIN customer_nation cn ON oh.o_custkey = cn.c_custkey
    LEFT JOIN popular_parts pp ON pp.order_count > 10
    LEFT JOIN supplier_summary ps ON pp.p_partkey = ps.ps_partkey
)
SELECT DISTINCT nation, 
       COUNT(o_orderkey) AS order_count, 
       SUM(total_revenue) AS total_revenue, 
       AVG(total_supply_cost) AS avg_supply_cost
FROM result_summary
WHERE total_revenue > 1000
GROUP BY nation
ORDER BY total_revenue DESC
LIMIT 10;