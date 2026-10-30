WITH top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 10
), 
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
), 
lineitem_summary AS (
    SELECT lo.l_orderkey, SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM lineitem lo
    WHERE lo.l_shipdate >= DATE '1997-01-01' AND lo.l_shipdate < DATE '1998-01-01'
    GROUP BY lo.l_orderkey
)

SELECT 
    c.c_name AS customer_name,
    COUNT(co.o_orderkey) AS total_orders,
    SUM(ls.total_revenue) AS total_revenue,
    ts.s_name AS top_supplier,
    ts.total_cost
FROM customer_orders co
JOIN customer c ON co.c_custkey = c.c_custkey
JOIN lineitem_summary ls ON co.o_orderkey = ls.l_orderkey
JOIN top_suppliers ts ON ls.total_revenue > 0 
GROUP BY c.c_name, ts.s_name, ts.total_cost
ORDER BY total_revenue DESC
LIMIT 20;