
WITH  top_nations AS (
    SELECT n.n_nationkey, n.n_name, r.r_name, 
           ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(s.s_acctbal) DESC) as rank
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
),
country_summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
           SUM(ps.ps_availqty) AS total_availqty, 
           AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_extendedprice
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY n.n_nationkey, n.n_name
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, c.c_mktsegment,
           DENSE_RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'F' AND c.c_acctbal IS NOT NULL
),
final_result AS (
    SELECT ns.n_name, cs.supplier_count, cs.total_availqty, cs.avg_extendedprice,
           ho.o_totalprice, ho.c_name, ho.c_mktsegment
    FROM country_summary cs
    JOIN top_nations ns ON cs.n_nationkey = ns.n_nationkey
    LEFT JOIN high_value_orders ho ON cs.n_name = ho.c_name
    WHERE ns.rank <= 5 AND cs.total_availqty > 100
)
SELECT DISTINCT f.n_name, f.supplier_count, f.total_availqty,
                COALESCE(f.avg_extendedprice, 0) AS avg_extendedprice,
                COALESCE(f.o_totalprice, 0) AS order_totalprice,
                f.c_name, f.c_mktsegment
FROM final_result f
ORDER BY f.n_name, f.supplier_count DESC
LIMIT 50;
