WITH supplier_summary AS (
    SELECT s_nationkey, COUNT(DISTINCT s_suppkey) AS supplier_count, SUM(s_acctbal) AS total_acctbal
    FROM supplier
    GROUP BY s_nationkey
),
part_summary AS (
    SELECT ps_partkey, SUM(ps_availqty) AS total_availqty, SUM(ps_supplycost * ps_availqty) AS total_supplycost
    FROM partsupp
    GROUP BY ps_partkey
),
nation_summary AS (
    SELECT n_nationkey, n_name, r_name, ss.supplier_count, ss.total_acctbal
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier_summary ss ON n.n_nationkey = ss.s_nationkey
),
order_summary AS (
    SELECT c.c_nationkey, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY c.c_nationkey
)

SELECT ns.n_name, 
       ns.r_name, 
       ns.supplier_count, 
       ns.total_acctbal, 
       os.order_count, 
       os.total_revenue, 
       ps.total_availqty, 
       ps.total_supplycost
FROM nation_summary ns
LEFT JOIN order_summary os ON ns.n_nationkey = os.c_nationkey
LEFT JOIN part_summary ps ON ps.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_supplycost > 1000)
WHERE ns.total_acctbal > 50000
ORDER BY ns.n_name DESC, os.total_revenue DESC;
