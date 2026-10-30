WITH region_summary AS (
    SELECT r.r_name AS region_name, 
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_supplier_balance
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
top_customers AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_order_value DESC
    LIMIT 5
),
part_summary AS (
    SELECT p.p_partkey,
           p.p_name,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           SUM(l.l_quantity) AS total_quantity_sold
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT r.region_name,
       r.nation_count,
       r.total_supplier_balance,
       c.c_name AS top_customer_name,
       c.total_order_value,
       p.p_name AS part_name,
       p.avg_supply_cost,
       p.total_quantity_sold
FROM region_summary r
CROSS JOIN top_customers c
CROSS JOIN part_summary p
WHERE r.nation_count > 5 AND c.total_order_value > 10000
ORDER BY r.region_name, c.total_order_value DESC, p.total_quantity_sold DESC;
