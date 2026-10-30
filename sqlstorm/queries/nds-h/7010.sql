
WITH ranked_orders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
top_orders AS (
    SELECT ro.o_orderkey, ro.total_revenue
    FROM ranked_orders ro
    WHERE ro.order_rank <= 10
),
suppliers_with_parts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT two.o_orderkey, swp.s_name, swp.p_name, two.total_revenue
FROM top_orders two
JOIN suppliers_with_parts swp ON two.total_revenue BETWEEN swp.ps_supplycost AND (swp.ps_supplycost * 1.2)
ORDER BY two.total_revenue DESC, swp.s_name;
