WITH supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           CONCAT(UPPER(SUBSTRING(s.s_name, 1, 1)), LOWER(SUBSTRING(s.s_name, 2))) AS formatted_name, 
           LENGTH(s.s_comment) AS comment_length
    FROM supplier s
    WHERE s.s_acctbal > 500.00
),
nation_info AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
part_count AS (
    SELECT ps.ps_suppkey, COUNT(ps.ps_partkey) AS total_parts
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
order_summary AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_order_value
    FROM orders o
    GROUP BY o.o_custkey
)
SELECT sd.formatted_name, ni.region_name, pc.total_parts, os.total_order_value
FROM supplier_details sd
JOIN nation_info ni ON sd.s_nationkey = ni.n_nationkey
JOIN part_count pc ON sd.s_suppkey = pc.ps_suppkey
LEFT JOIN order_summary os ON sd.s_suppkey = os.o_custkey
WHERE sd.comment_length > 50
ORDER BY sd.formatted_name, ni.region_name;
