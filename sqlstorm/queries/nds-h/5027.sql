WITH regional_suppliers AS (
    SELECT n.n_name as nation_name,
           r.r_name as region_name,
           COUNT(s.s_suppkey) as supplier_count,
           SUM(s.s_acctbal) as total_acct_balance
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name, r.r_name
),
top_part_data AS (
    SELECT ps.ps_partkey,
           p.p_name,
           p.p_brand,
           SUM(ps.ps_availqty) as total_available_quantity,
           SUM(ps.ps_supplycost * ps.ps_availqty) as total_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, p.p_name, p.p_brand
    HAVING SUM(ps.ps_availqty) > 1000
),
customer_order_summary AS (
    SELECT c.c_custkey,
           SUM(o.o_totalprice) as total_spent,
           COUNT(o.o_orderkey) as order_count,
           MAX(o.o_orderdate) as last_order_date
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 5000
)
SELECT r.nation_name,
       r.region_name,
       r.supplier_count,
       r.total_acct_balance,
       tp.p_name,
       tp.total_available_quantity,
       tp.total_supply_cost,
       cos.total_spent,
       cos.order_count,
       cos.last_order_date
FROM regional_suppliers r
JOIN top_part_data tp ON r.nation_name = 'Germany'
JOIN customer_order_summary cos ON cos.total_spent > 10000
WHERE r.supplier_count > 5
ORDER BY r.region_name, tp.total_supply_cost DESC;
