WITH supplier_parts AS (
    SELECT s.s_suppkey, s.s_name, p.p_name, p.p_container, ps.ps_supplycost, 
           CONCAT(s.s_name, ' supplies ', p.p_name, ' in ', p.p_container) AS supplier_info
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, 
           CONCAT('Order ', o.o_orderkey, ' placed by ', c.c_name, ' on ', o.o_orderdate) AS order_info
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
line_items_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT sp.supplier_info, co.order_info, lis.total_revenue, lis.unique_parts
FROM supplier_parts sp
JOIN customer_orders co ON sp.s_suppkey = co.c_custkey
JOIN line_items_summary lis ON co.o_orderkey = lis.l_orderkey
WHERE sp.ps_supplycost > 100.00
ORDER BY lis.total_revenue DESC;
