WITH  supplier_data AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ps.ps_availqty, ps.ps_supplycost, p.p_partkey, p.p_name
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 10000
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderpriority
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1997-01-01'
),
lineitem_summary AS (
    SELECT lo.l_orderkey, SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue, COUNT(lo.l_orderkey) AS item_count
    FROM lineitem lo
    WHERE lo.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY lo.l_orderkey
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT cs.c_custkey, cs.c_name, cs.o_orderkey, cs.o_orderdate, ls.total_revenue, ls.item_count, ns.n_name AS nation_name, sd.s_name AS supplier_name
FROM customer_orders cs
JOIN lineitem_summary ls ON cs.o_orderkey = ls.l_orderkey
JOIN supplier_data sd ON sd.ps_availqty > 0
JOIN nation_summary ns ON sd.s_nationkey = ns.n_nationkey
WHERE ls.total_revenue > 50000
ORDER BY cs.o_orderdate DESC, ls.total_revenue DESC;