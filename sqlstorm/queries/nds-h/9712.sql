
WITH supplier_part AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_retailprice, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
customer_order AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderpriority
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS line_count, AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.o_orderkey,
    co.o_orderdate,
    ls.total_revenue,
    ls.line_count,
    ls.avg_quantity
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN supplier_part sp ON s.s_suppkey = sp.s_suppkey
JOIN customer_order co ON sp.p_partkey = co.o_orderkey
JOIN lineitem_summary ls ON co.o_orderkey = ls.l_orderkey
WHERE r.r_name = 'Europe' AND co.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY ls.total_revenue DESC, co.o_orderdate ASC
LIMIT 100;
