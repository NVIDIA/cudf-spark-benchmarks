
WITH region_summary AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count, SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
customer_summary AS (
    SELECT c.c_nationkey, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
),
part_supplier_summary AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_available_qty, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT 
    r.r_name,
    rs.nation_count,
    rs.total_acctbal,
    cs.total_order_value,
    p.p_name,
    pss.total_available_qty,
    pss.total_supply_cost
FROM region_summary rs
JOIN region r ON rs.r_name = r.r_name
LEFT JOIN customer_summary cs ON cs.c_nationkey = r.r_regionkey
LEFT JOIN part_supplier_summary pss ON pss.p_partkey IN (SELECT p.p_partkey FROM part p)
LEFT JOIN part p ON p.p_partkey = pss.p_partkey
ORDER BY r.r_name, cs.total_order_value DESC
LIMIT 100;
