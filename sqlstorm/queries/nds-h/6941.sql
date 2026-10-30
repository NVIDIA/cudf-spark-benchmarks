WITH supplier_part AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, s.s_name, s.s_nationkey, ps.ps_supplycost, 
           p.p_brand, p.p_type, p.p_size
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), order_summary AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_nationkey, o.o_orderstatus
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
), lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           SUM(l.l_quantity) AS total_quantity, COUNT(*) AS line_count, 
           SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT n.n_name, COUNT(DISTINCT o.o_orderkey) AS order_count, 
       SUM(ls.revenue) AS total_revenue, SUM(ls.total_quantity) AS total_quantity,
       AVG(sp.ps_supplycost) AS avg_supply_cost
FROM order_summary o
JOIN lineitem_summary ls ON o.o_orderkey = ls.l_orderkey
JOIN nation n ON o.c_nationkey = n.n_nationkey
JOIN supplier_part sp ON sp.ps_partkey IN (
    SELECT p.p_partkey 
    FROM part p 
    WHERE p.p_brand = 'Brand#34' AND p.p_type LIKE '%metal%'
)
WHERE o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
AND o.o_orderstatus = 'F'
GROUP BY n.n_name
ORDER BY total_revenue DESC, order_count DESC;