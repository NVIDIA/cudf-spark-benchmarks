WITH  supplier_rank AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), part_availability AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_availqty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
), order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
), customer_activity AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING COUNT(DISTINCT o.o_orderkey) > 0
)
SELECT DISTINCT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    pa.total_availqty,
    os.total_price,
    CASE WHEN ca.order_count IS NULL THEN 'No Orders' ELSE 'Has Orders' END AS order_status
FROM supplier_rank sr
LEFT JOIN supplier s ON sr.s_suppkey = s.s_suppkey
CROSS JOIN part p
LEFT JOIN part_availability pa ON p.p_partkey = pa.p_partkey
LEFT JOIN order_summary os ON os.o_orderdate = cast('1998-10-01' as date)
LEFT JOIN customer_activity ca ON ca.c_custkey = s.s_suppkey
WHERE sr.rank <= 3 AND (pa.total_availqty IS NULL OR pa.total_availqty > 0)
ORDER BY supplier_name, part_name
LIMIT 10;