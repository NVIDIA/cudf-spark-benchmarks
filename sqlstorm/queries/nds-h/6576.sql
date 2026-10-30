WITH supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 5000
), relevant_parts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_brand, p.p_type
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice BETWEEN 50 AND 200
), order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
    GROUP BY o.o_orderkey
)
SELECT rd.nation_name, rp.p_brand, rp.p_type, SUM(os.total_revenue) AS total_revenue
FROM supplier_details rd
JOIN relevant_parts rp ON rd.s_suppkey = rp.ps_suppkey
JOIN order_summary os ON rp.ps_partkey = rp.ps_partkey
GROUP BY rd.nation_name, rp.p_brand, rp.p_type
ORDER BY total_revenue DESC
LIMIT 10;