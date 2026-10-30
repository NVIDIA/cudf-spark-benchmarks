WITH nation_summary AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
order_summary AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_order_value
    FROM orders o
    GROUP BY o.o_custkey
)
SELECT ps.ps_partkey, p.p_name, ps.ps_supplycost, p.p_retailprice,
       ns.n_name AS supplier_nation, ns.total_acctbal, os.total_order_value
FROM partsupp ps
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation_summary ns ON s.s_nationkey = ns.n_nationkey
JOIN order_summary os ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') 
WHERE p.p_size BETWEEN 20 AND 50
AND p.p_type LIKE 'rubber%'
ORDER BY ns.total_acctbal DESC, os.total_order_value DESC
LIMIT 100;