WITH  supplier_parts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 10000.00
),
order_summary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price, COUNT(l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
customer_region AS (
    SELECT c.c_custkey, c.c_name, n.n_regionkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'Europe')
)
SELECT cr.c_name, sp.s_name, sp.p_name, sp.ps_availqty, os.total_price, os.item_count
FROM customer_region cr
JOIN order_summary os ON cr.c_custkey = os.o_custkey
JOIN supplier_parts sp ON os.item_count > 0 AND sp.ps_partkey IN (
    SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 50
)
ORDER BY os.total_price DESC, cr.c_name ASC;