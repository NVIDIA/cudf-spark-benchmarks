WITH top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_value DESC
    LIMIT 10
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount, c.c_mktsegment
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_mktsegment
),
supplier_contribution AS (
    SELECT os.o_orderkey, os.total_amount, ts.s_suppkey, ts.s_name
    FROM order_summary os
    JOIN lineitem l ON os.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN top_suppliers ts ON ps.ps_suppkey = ts.s_suppkey
)
SELECT sc.o_orderkey, sc.total_amount, sc.s_name, SUM(sc.total_amount) OVER (PARTITION BY sc.s_suppkey) AS supplier_total_amount
FROM supplier_contribution sc
ORDER BY sc.s_name, sc.o_orderkey;