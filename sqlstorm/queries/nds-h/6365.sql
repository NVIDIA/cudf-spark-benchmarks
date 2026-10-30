
WITH region_summary AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
),
supplier_summary AS (
    SELECT s.s_nationkey, COUNT(s.s_suppkey) AS supplier_count, SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    GROUP BY s.s_nationkey
),
top_parts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    ORDER BY total_cost DESC
    LIMIT 10
)
SELECT 
    rs.r_name,
    rs.nation_count,
    ss.supplier_count,
    ss.total_acctbal,
    tp.total_cost
FROM region_summary rs
JOIN supplier_summary ss ON rs.r_regionkey = ss.s_nationkey
JOIN top_parts tp ON tp.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#1')
WHERE rs.nation_count > 5
ORDER BY rs.r_name, ss.supplier_count DESC;
