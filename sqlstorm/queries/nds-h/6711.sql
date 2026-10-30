WITH region_summary AS (
    SELECT r_regionkey, r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
),
supplier_summary AS (
    SELECT s.s_nationkey, SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    GROUP BY s.s_nationkey
),
part_supplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supplycost, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
customer_order_summary AS (
    SELECT c.c_nationkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
)
SELECT 
    rs.r_name,
    rs.nation_count,
    COALESCE(ss.total_acctbal, 0) AS total_supplier_acctbal,
    COALESCE(ps.total_supplycost, 0) AS total_part_supplycost,
    COALESCE(cs.order_count, 0) AS total_orders,
    COALESCE(cs.total_spent, 0) AS total_revenue
FROM region_summary rs
LEFT JOIN supplier_summary ss ON ss.s_nationkey = rs.r_regionkey
LEFT JOIN part_supplier ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type LIKE 'BRASS%') 
LEFT JOIN customer_order_summary cs ON cs.c_nationkey = rs.r_regionkey
ORDER BY rs.nation_count DESC, total_revenue DESC;