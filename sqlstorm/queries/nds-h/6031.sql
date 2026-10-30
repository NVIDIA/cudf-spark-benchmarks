
WITH recent_orders AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice
    FROM orders
    WHERE o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
customer_data AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_mktsegment
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE n.n_name IN ('USA', 'Germany', 'Japan')
),
supplier_parts AS (
    SELECT ps.ps_partkey, s.s_suppkey, s.s_name
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0
),
line_item_summaries AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    cd.c_name,
    COUNT(ro.o_orderkey) AS order_count,
    SUM(lis.total_revenue) AS total_revenue,
    p.p_brand,
    p.p_type,
    SUM(ps.ps_supplycost) AS total_supply_cost
FROM recent_orders ro
JOIN customer_data cd ON ro.o_custkey = cd.c_custkey
JOIN line_item_summaries lis ON ro.o_orderkey = lis.l_orderkey
JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE ro.o_totalprice > 1000
GROUP BY cd.c_name, p.p_brand, p.p_type
ORDER BY total_revenue DESC, order_count DESC;
