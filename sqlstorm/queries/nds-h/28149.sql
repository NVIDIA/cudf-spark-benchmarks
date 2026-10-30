WITH supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_comment, SUBSTRING(s.s_address, 1, 15) AS short_address
    FROM supplier s
),
nation_details AS (
    SELECT n.n_nationkey, n.n_name, n.n_comment
    FROM nation n
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
part_supply_summary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    sd.s_name,
    n.n_name AS nation_name,
    co.order_count,
    co.total_spent,
    pss.total_available,
    pss.avg_supply_cost,
    CONCAT('Supplier: ', sd.s_name, ' from ', sd.short_address, ' serving ', n.n_name) AS supplier_summary
FROM supplier_details sd
JOIN nation_details n ON sd.s_nationkey = n.n_nationkey
JOIN customer_orders co ON sd.s_nationkey = co.c_custkey
JOIN part_supply_summary pss ON sd.s_suppkey = pss.ps_partkey
WHERE co.total_spent > 1000
ORDER BY co.total_spent DESC, sd.s_name;
