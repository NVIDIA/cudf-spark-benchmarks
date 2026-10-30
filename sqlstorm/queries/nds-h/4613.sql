
WITH regional_suppliers AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name, r.r_name
),
order_totals AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate > DATE '1997-01-01'
    GROUP BY o.o_custkey
),
high_value_customers AS (
    SELECT c.c_custkey, c.c_name, COALESCE(ot.total_order_value, 0) AS order_value
    FROM customer c
    LEFT JOIN order_totals ot ON c.c_custkey = ot.o_custkey
    WHERE COALESCE(ot.total_order_value, 0) > 10000
),
supplier_part_info AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, p.p_retailprice, 
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS supply_rank
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 10
),
top_suppliers AS (
    SELECT DISTINCT s.s_suppkey, s.s_name, spi.p_name, spi.p_retailprice
    FROM supplier s
    JOIN supplier_part_info spi ON s.s_suppkey = spi.ps_suppkey
    WHERE spi.supply_rank = 1
),
final_report AS (
    SELECT hvc.c_name, hvc.order_value, ts.s_name, ts.p_name, ts.p_retailprice
    FROM high_value_customers hvc
    LEFT JOIN top_suppliers ts ON hvc.c_custkey = ts.s_suppkey
)
SELECT r.nation_name, r.region_name, COUNT(r.supplier_count) AS total_suppliers,
       SUM(f.order_value) AS high_value_orders
FROM regional_suppliers r
LEFT JOIN final_report f ON r.nation_name = f.c_name
GROUP BY r.nation_name, r.region_name
ORDER BY total_suppliers DESC, high_value_orders DESC;
