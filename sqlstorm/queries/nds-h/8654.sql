WITH supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
),
top_parts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    ORDER BY total_value DESC
    LIMIT 10
),
orders_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    si.s_name AS supplier_name,
    si.nation_name,
    tp.ps_partkey,
    os.o_orderkey,
    os.total_order_value,
    tp.total_value AS part_total_value
FROM supplier_info si
JOIN top_parts tp ON si.s_suppkey = tp.ps_partkey
JOIN orders_summary os ON os.total_order_value > tp.total_value
WHERE si.nation_name = 'USA'
ORDER BY os.total_order_value DESC, tp.total_value DESC;
